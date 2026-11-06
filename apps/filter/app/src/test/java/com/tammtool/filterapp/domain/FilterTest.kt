package com.tammtool.filterapp.domain

import com.tammtool.filterapp.R
import org.junit.Assert.assertEquals
import org.junit.Test

class FilterTest {

    private fun sample(min: Float = 0f, max: Float = 1f) = Filter(
        id = "grayscale",
        shaderName = "grayscale.agsl",
        labelRes = R.string.filter_none,
        uniform = "luma",
        minIntensity = min,
        maxIntensity = max
    )

    @Test
    fun intensityIsClampedToDeclaredRange() {
        assertEquals(0f, sample().clampIntensity(-3f), 0f)
        assertEquals(1f, sample().clampIntensity(9f), 0f)
        assertEquals(0.4f, sample().clampIntensity(0.4f), 0f)
    }

    @Test
    fun wideRangeIsRespected() {
        val f = Filter("contrast", "contrast.agsl", R.string.filter_none, "amount", 0f, 2f)
        assertEquals(1.7f, f.clampIntensity(1.7f), 0f)
    }

    @Test
    fun nanAndInfinityFallBackToMinimum() {
        assertEquals(0f, sample().clampIntensity(Float.NaN), 0f)
        assertEquals(0f, sample().clampIntensity(Float.POSITIVE_INFINITY), 0f)
    }

    @Test
    fun assetPathPointsAtShadersFolder() {
        assertEquals("shaders/grayscale.agsl", sample().assetPath)
    }

    @Test(expected = IllegalArgumentException::class)
    fun rejectsBadId() {
        Filter("Bad ID!", "x.agsl", R.string.filter_none)
    }

    @Test(expected = IllegalArgumentException::class)
    fun rejectsUnknownShaderExtension() {
        Filter("ok_id", "ok.txt", R.string.filter_none)
    }
}
