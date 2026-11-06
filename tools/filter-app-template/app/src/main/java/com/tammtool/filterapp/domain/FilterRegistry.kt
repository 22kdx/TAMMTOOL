package com.tammtool.filterapp.domain

import com.tammtool.filterapp.R

/**
 * قائمة الفلاتر = المصدر الوحيد للحقيقة عن «ما هو موجود».
 *
 * كل فلتر له ملف شيدر واحد باسم `shaderName` في `app/src/main/assets/shaders/`، و
 * `tools/verify-filter-app.sh` يفحص أن كل اسم هنا له ملف فعلاً (فحص متقاطع بين شيدر وكود —
 * هو الفحص الذي يكشف «التطبيق يبنى لكنه يسقط عند التشغيل»).
 */
object FilterRegistry {

    val all: List<Filter> = listOf(
        Filter("none", "identity.agsl", R.string.filter_none),
        Filter("grayscale", "grayscale.agsl", R.string.filter_grayscale, "luma"),
        Filter("sepia", "sepia.agsl", R.string.filter_sepia, "amount"),
        Filter("contrast", "contrast.agsl", R.string.filter_contrast, "amount", 0f, 2f),
        Filter("vignette", "vignette.agsl", R.string.filter_vignette, "radius", 0f, 1f),
        Filter("pixelate", "pixelate.agsl", R.string.filter_pixelate, "block", 1f, 32f),
        Filter("blur", "gaussian_blur.agsl", R.string.filter_blur, "sigma", 0f, 12f)
    )

    val ids: List<String> get() = all.map { it.id }

    fun byId(id: String): Filter? = all.firstOrNull { it.id == id }

    /** الفلتر الافتراضي عند أول تشغيل — لا انهيار إن تغيّر الترتيب. */
    val default: Filter get() = byId("none") ?: all.first()

    /** عدد التكرارات التي يجب أن تُطابق عدد ملفات الشيدر (يستخدمها سكربت التحقق). */
    val size: Int get() = all.size
}
