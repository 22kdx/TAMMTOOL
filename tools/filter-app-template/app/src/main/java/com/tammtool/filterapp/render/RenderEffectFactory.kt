package com.tammtool.filterapp.render

import android.graphics.RenderEffect
import android.os.Build
import com.tammtool.filterapp.domain.Filter
import com.tammtool.filterapp.domain.FilterCapability
import com.tammtool.filterapp.domain.RenderPath

/**
 * قرار المسار + التنفيذ في مكان واحد، حتى لا يتكرر شرط `Build.VERSION` في كل شاشة
 * (التكرار هنا = تسرّب NoClassDefFoundError إلى أجهزة API 24).
 */
object RenderEffectFactory {

    /** يُرجع null عند «بدون فلتر» أو حين لا مسار متاح ⇒ المتلقّي يعرض الصورة كما هي. */
    fun create(filter: Filter, intensity: Float, shaderSource: String?): RenderEffect? {
        if (filter.id == "none") return null
        val source = shaderSource ?: return null
        return if (Build.VERSION.SDK_INT >= FilterCapability.RUNTIME_SHADER_API &&
            FilterCapability.current() == RenderPath.AGSL
        ) {
            AgslEffectBridge.build(filter, intensity, source)
        } else {
            null   // مسار GLES مخطط له — راجع FILTER_APP_TOOLCHAIN.md §4 «ما لم يُنفَّذ»
        }
    }

    /** فصل التحميل الحساس لـ API 33 في صف مستقل. */
    private object AgslEffectBridge {
        fun build(filter: Filter, intensity: Float, source: String): RenderEffect? =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                AgslFilterRenderer().effect(filter, intensity, source)
            } else {
                null
            }
    }
}
