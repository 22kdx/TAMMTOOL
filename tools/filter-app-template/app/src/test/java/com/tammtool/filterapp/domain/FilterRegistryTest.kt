package com.tammtool.filterapp.domain

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * لا Android هنا ⇒ تُشغَّل على JVM: ./scripts/build-apk.sh unit-test filter
 * الفحوص تختصر ما كان ينقص التطبيقين (GAP_TO_APK.md C7).
 */
class FilterRegistryTest {

    @Test
    fun idsAreUnique() {
        assertEquals(FilterRegistry.all.size, FilterRegistry.ids.distinct().size)
    }

    @Test
    fun everyFilterHasOneShaderFile() {
        // قاعدةCross-file: اسم الشيدر موجود مرة واحدة على الأقل وغير مكرر على فلترين
        val shaders = FilterRegistry.all.map { it.shaderName }
        assertEquals(shaders.size, shaders.distinct().size)
    }

    @Test
    fun defaultFilterIsNoop() {
        assertEquals("none", FilterRegistry.default.id)
    }

    @Test
    fun lookupRejectsUnknownId() {
        assertNull(FilterRegistry.byId("does-not-exist"))
        assertNotNull(FilterRegistry.byId("grayscale"))
    }

    @Test
    fun countMatchesDocumentedSize() {
        assertTrue("الفلاتر يجب أن تكون 7 على الأقل لتغطية الشريحة", FilterRegistry.size >= 7)
    }
}
