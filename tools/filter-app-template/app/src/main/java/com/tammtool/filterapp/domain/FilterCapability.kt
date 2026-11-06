package com.tammtool.filterapp.domain

import android.os.Build

/**
 * AGSL (`RuntimeShader`) متاح من API 33 فقط؛ ما دونه نحتاج مسار GLES.
 * دالة نقية على رقم الإصدار ⇒ قابلة للاختبار على JVM بلا محاكي.
 */
enum class RenderPath { AGSL, GLES, NONE }

object FilterCapability {

    const val RUNTIME_SHADER_API = 33

    fun renderPathFor(sdkInt: Int, hasGlEs30: Boolean): RenderPath = when {
        sdkInt >= RUNTIME_SHADER_API -> RenderPath.AGSL
        hasGlEs30 -> RenderPath.GLES
        else -> RenderPath.NONE
    }

    fun current(): RenderPath = renderPathFor(
        sdkInt = Build.VERSION.SDK_INT,
        hasGlEs30 = Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP
    )

    /** هل يمكن تطبيق الفلتر `filter` على هذا الجهاز الآن؟ (فلتر «none» يعمل دائماً) */
    fun supports(filter: Filter, path: RenderPath): Boolean =
        filter.id == "none" || path != RenderPath.NONE
}
