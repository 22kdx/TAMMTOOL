package com.tammtool.filterapp.domain

/**
 * وصف فلتر واحد: اسم المعرّف، اسم الملف في assets، ومعاملات قابلة للضبط.
 *
 * لا Android هنا عمداً ⇒ يُختبر على JVM صافٍ (`./scripts/build-apk.sh unit-test filter`)،
 * وهو نفس الدرس من GAP_TO_APK.md C7: منطق بلا إطار = منطق قابل للاختبار.
 */
data class Filter(
    val id: String,
    val shaderName: String,
    val labelRes: Int,
    val uniform: String? = null,
    val minIntensity: Float = 0f,
    val maxIntensity: Float = 1f
) {
    init {
        require(id.matches(ID_REGEX)) { "معرف الفلتر غير صالح: $id" }
        require(shaderName.endsWith(".agsl") || shaderName.endsWith(".glsl")) {
            "امتداد الشيدر يجب أن يكون .agsl أو .glsl: $shaderName"
        }
    }

    /** يُرسل إلى Shader كـ uniform واحد؛ يُقصّ إلى النطاق المعلن للفلتر. */
    fun clampIntensity(raw: Float): Float {
        if (raw.isNaN() || raw.isInfinite()) return minIntensity
        return raw.coerceIn(minIntensity, maxIntensity)
    }

    /** اسم المورد بلا امتداد، كما يُفتح من assets. */
    val assetPath: String get() = "shaders/$shaderName"

    private companion object {
        val ID_REGEX = Regex("^[a-z0-9_]{3,32}$")
    }
}
