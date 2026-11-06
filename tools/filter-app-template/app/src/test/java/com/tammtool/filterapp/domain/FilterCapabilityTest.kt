package com.tammtool.filterapp.domain

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class FilterCapabilityTest {

    @Test
    fun usesAgslFromApi33() {
        assertEquals(RenderPath.AGSL, FilterCapability.renderPathFor(33, false))
        assertEquals(RenderPath.AGSL, FilterCapability.renderPathFor(35, true))
    }

    @Test
    fun fallsBackToGlesOnOlderDevices() {
        assertEquals(RenderPath.GLES, FilterCapability.renderPathFor(26, true))
        assertEquals(RenderPath.GLES, FilterCapability.renderPathFor(24, true))
    }

    @Test
    fun reportsNoneWithoutGles30() {
        assertEquals(RenderPath.NONE, FilterCapability.renderPathFor(24, false))
    }

    @Test
    fun noopFilterAlwaysSupported() {
        val none = FilterRegistry.default
        assertTrue(FilterCapability.supports(none, RenderPath.NONE))
    }

    @Test
    fun realFiltersNeedAPath() {
        val gray = FilterRegistry.byId("grayscale")!!
        assertFalse(FilterCapability.supports(gray, RenderPath.NONE))
        assertTrue(FilterCapability.supports(gray, RenderPath.AGSL))
    }
}
