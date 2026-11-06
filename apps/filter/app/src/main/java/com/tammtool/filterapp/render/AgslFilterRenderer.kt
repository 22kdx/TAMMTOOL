package com.tammtool.filterapp.render

import android.graphics.RenderEffect
import android.graphics.RuntimeShader
import android.os.Build
import androidx.annotation.RequiresApi
import com.tammtool.filterapp.domain.Filter

/**
 * مسار API 33+: فلاتر AGSL عبر RenderEffect بدون أي مكتبة خارجية أو ملف .so.
 *
 * ملاحظة مهمة للوكيل 1: هذا الكلاس **لا يُحمَّل** إلا عند `SDK_INT >= 33` — يلفّه
 * `RenderEffectFactory.create` بشرط، لأن تحميل صف يشير إلى RuntimeShader على API أقل
 * يسقط بـ NoClassDefFoundError عند تشغيل الحزمة، لا عند الترجمة.
 */
@RequiresApi(Build.VERSION_CODES.TIRAMISU)
class AgslFilterRenderer {

    fun effect(filter: Filter, intensity: Float, shaderSource: String): RenderEffect {
        val shader = RuntimeShader(shaderSource)
        val value = filter.clampIntensity(intensity)
        return when (filter.uniform) {
            null -> RenderEffect.CreateRuntimeShaderEffect(shader, "content")
            else -> {
                shader.setFloat(filter.uniform!!, value)
                RenderEffect.CreateRuntimeShaderEffect(shader, "content")
            }
        }
    }

    companion object {
        const val MIN_API = 33
    }
}
