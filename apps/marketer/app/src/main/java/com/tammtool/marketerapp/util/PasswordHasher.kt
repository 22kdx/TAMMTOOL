package com.tammtool.marketerapp.util

import java.security.GeneralSecurityException
import java.security.MessageDigest
import java.security.NoSuchAlgorithmException
import java.security.SecureRandom
import javax.crypto.SecretKeyFactory
import javax.crypto.spec.PBEKeySpec

/**
 * تجزئة كلمات المرور — يسدّ الفجوة C1 في GAP_TO_APK.md (كان login() يقبل أي كلمة مرور).
 *
 * الصيغة المخزّنة:  pbkdf2:<algorithm>:<iterations>$<salt-hex>$<hash-hex>
 * لا اعتماديات Android هنا عمداً ⇒ تُختبر بوحدة على JVM صافٍ (src/test/java).
 * PBKDF2WithHmacSHA256 غير متوفر على API 24/25، لذا يُسقط المسار إلى SHA1 ويُسجَّل اسم
 * الخوارزمية داخل الصيغة نفسها، فيُتحقق من المفتاح القديم بالخوارزمية التي جُزّئ بها.
 */
object PasswordHasher {

    private const val PREFIX = "pbkdf2"
    private const val PRIMARY_ALGORITHM = "PBKDF2WithHmacSHA256"
    private const val FALLBACK_ALGORITHM = "PBKDF2WithHmacSHA1"
    private const val ITERATIONS = 120000
    private const val KEY_BITS = 256
    private const val SALT_BYTES = 16
    private const val SEPARATOR = '$'

    private val secureRandom = SecureRandom()
    private val hexChars = "0123456789abcdef".toCharArray()

    /** أقل طول مقبول لكلمة المرور — يفحصه ViewModel أيضاً لرسالة أوضح. */
    const val MIN_PASSWORD_LENGTH = 8

    fun availableAlgorithm(): String = try {
        SecretKeyFactory.getInstance(PRIMARY_ALGORITHM)
        PRIMARY_ALGORITHM
    } catch (e: NoSuchAlgorithmException) {
        FALLBACK_ALGORITHM
    }

    fun hash(password: String): String {
        require(password.length >= MIN_PASSWORD_LENGTH) {
            "كلمة المرور يجب ألا تقل عن " + MIN_PASSWORD_LENGTH + " حرفاً"
        }
        val algorithm = availableAlgorithm()
        val salt = ByteArray(SALT_BYTES).also { secureRandom.nextBytes(it) }
        val digest = pbkdf2(algorithm, password, salt, ITERATIONS)
        return listOf(PREFIX + ":" + algorithm + ":" + ITERATIONS, toHex(salt), toHex(digest))
            .joinToString(SEPARATOR.toString())
    }

    /** تحقق آمن: بلا مقارنة نصية مباشرة وبلا تسريب لوجود الحساب (نفس رسالة الفشل). */
    fun verify(password: String, stored: String?): Boolean {
        val value = stored?.trim().orEmpty()
        if (value.isEmpty() || !isStoredHash(value)) return false
        val parts = value.split(SEPARATOR)
        if (parts.size != 3) return false
        val meta = parts[0].split(':')
        if (meta.size != 3 || meta[0] != PREFIX) return false
        val iterations = meta[2].toIntOrNull() ?: return false
        if (iterations < 1000) return false
        val salt = fromHex(parts[1]) ?: return false
        val expected = fromHex(parts[2]) ?: return false
        val actual = try {
            pbkdf2(meta[1], password, salt, iterations)
        } catch (e: GeneralSecurityException) {
            return false
        } catch (e: IllegalArgumentException) {
            return false
        }
        return MessageDigest.isEqual(expected, actual)
    }

    /** هل الصيغة من إنتاج هذا الكلاس (لا نص صريح ولا تجزئة خارجية)؟ */
    fun isStoredHash(stored: String?): Boolean =
        stored != null && stored.startsWith(PREFIX + ":")

    /** يُستدعى بعد نجاح الدخول لترقية الخوارزمية/عدد التكرارات بصمت. */
    fun needsRehash(stored: String?): Boolean {
        if (!isStoredHash(stored)) return true
        val meta = stored!!.split(SEPARATOR).firstOrNull().orEmpty().split(':')
        if (meta.size != 3) return true
        val iterations = meta[2].toIntOrNull() ?: return true
        return meta[1] != availableAlgorithm() || iterations < ITERATIONS
    }

    private fun pbkdf2(algorithm: String, password: String, salt: ByteArray, iterations: Int): ByteArray {
        val spec = PBEKeySpec(password.toCharArray(), salt, iterations, KEY_BITS)
        return try {
            SecretKeyFactory.getInstance(algorithm).generateSecret(spec).encoded
        } catch (e: NoSuchAlgorithmException) {
            // مفتاح جُزّئ بخوارزمية غير متوفرة هنا — الرفض آمن أكثر من القبول
            throw GeneralSecurityException("PBKDF2 algorithm unavailable: " + algorithm, e)
        } finally {
            spec.clearPassword()
        }
    }

    private fun toHex(bytes: ByteArray): String {
        val out = StringBuilder(bytes.size * 2)
        for (b in bytes) {
            val v = b.toInt() and 0xFF
            out.append(hexChars[v ushr 4])
            out.append(hexChars[v and 0x0F])
        }
        return out.toString()
    }

    private fun fromHex(text: String): ByteArray? {
        if (text.isEmpty() || text.length % 2 != 0) return null
        val out = ByteArray(text.length / 2)
        for (i in out.indices) {
            val hi = Character.digit(text[i * 2], 16)
            val lo = Character.digit(text[i * 2 + 1], 16)
            if (hi < 0 || lo < 0) return null
            out[i] = ((hi shl 4) or lo).toByte()
        }
        return out
    }
}
