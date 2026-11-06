package com.tammtool.filterapp.data

import android.content.res.AssetManager
import com.tammtool.filterapp.domain.Filter
import java.io.IOException

/**
 * قراءة نصوص الشيدرات من `assets/shaders/` ووضعها في ذاكرة التخزين المؤقت.
 *
 * لا `res/raw`: الملفات غير XML في `res/` تصنع مشاكل AAPT2 مع أسماء فيها `_` (مسجّل في
 * TROUBLESHOOTING.md §5.2)، وassets تُنسخ كما هي بلا معالجة.
 */
class ShaderSourceRepository(private val assets: AssetManager) {

    private val cache = HashMap<String, String>()

    fun read(filter: Filter): String? {
        cache[filter.assetPath]?.let { return it }
        return try {
            val text = assets.open(filter.assetPath).bufferedReader().use { it.readText() }
            cache[filter.assetPath] = text
            text
        } catch (e: IOException) {
            null
        }
    }

    /** للوحدة: هل الملف موجود؟ لا نقرأه كاملاً. */
    fun exists(filter: Filter): Boolean = try {
        assets.open(filter.assetPath).close()
        true
    } catch (e: IOException) {
        false
    }

    fun clear() = cache.clear()
}
