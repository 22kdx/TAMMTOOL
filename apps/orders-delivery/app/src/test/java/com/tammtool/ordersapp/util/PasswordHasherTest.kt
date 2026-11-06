package com.tammtool.ordersapp.util

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * اختبارات منطق الأمان (JVM صافٍ — بلا Robolectric ولا جهاز).
 * تشغيلها: ./scripts/build-apk.sh unit-test orders-delivery
 */
class PasswordHasherTest {

    private val password = "Tamm#2026!x"

    @Test
    fun hashThenVerifySucceeds() {
        assertTrue(PasswordHasher.verify(password, PasswordHasher.hash(password)))
    }

    @Test
    fun wrongPasswordFails() {
        val stored = PasswordHasher.hash(password)
        assertFalse(PasswordHasher.verify("Tamm#2026!y", stored))
    }

    @Test
    fun nullEmptyAndPlaintextStoredNeverAuthenticate() {
        assertFalse(PasswordHasher.verify(password, null))
        assertFalse(PasswordHasher.verify(password, ""))
        assertFalse(PasswordHasher.verify(password, password))
    }

    @Test
    fun samePasswordHashesDifferBySalt() {
        val a = PasswordHasher.hash(password)
        val b = PasswordHasher.hash(password)
        assertNotEquals(a, b)
        assertTrue(PasswordHasher.verify(password, a))
        assertTrue(PasswordHasher.verify(password, b))
    }

    @Test
    fun storedFormatCarriesAlgorithmAndIterations() {
        val meta = PasswordHasher.hash(password).split('$').first().split(':')
        assertEquals(3, meta.size)
        assertEquals("pbkdf2", meta[0])
        assertTrue(meta[1].startsWith("PBKDF2WithHmacSHA"))
        assertTrue(meta[2].toInt() >= 100000)
    }

    @Test
    fun tamperedDigestFails() {
        val stored = PasswordHasher.hash(password)
        val last = stored.last()
        val flipped = stored.substring(0, stored.length - 1) + if (last == 'a') 'b' else 'a'
        assertFalse(PasswordHasher.verify(password, flipped))
    }

    @Test
    fun weakStoredFormatIsRejected() {
        // iterations ضعيفة أو حقول ناقصة ⇒ لا دخول مهما طابق الباقي
        assertFalse(PasswordHasher.verify(password, "pbkdf2:PBKDF2WithHmacSHA256:10$salt()$digest()"))
        assertFalse(PasswordHasher.verify(password, "pbkdf2:PBKDF2WithHmacSHA256:120000"))
    }

    @Test
    fun shortPasswordIsRejectedAtHashTime() {
        try {
            PasswordHasher.hash("abc")
            throw AssertionError("expected IllegalArgumentException for a short password")
        } catch (expected: IllegalArgumentException) {
            assertTrue(expected.message!!.isNotEmpty())
        }
    }

    @Test
    fun freshlyHashedValueNeedsNoRehash() {
        val stored = PasswordHasher.hash(password)
        assertFalse(PasswordHasher.needsRehash(stored))
        assertTrue(PasswordHasher.needsRehash(""))
        assertTrue(PasswordHasher.needsRehash(password))
    }

    private fun salt() = "00112233445566778899aabbccddeeff"
    private fun digest() = "ffeeddccbbaa99887766554433221100"
}
