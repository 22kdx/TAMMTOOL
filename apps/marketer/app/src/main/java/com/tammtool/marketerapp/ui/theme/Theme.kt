package com.tammtool.marketerapp.ui.theme

import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.ui.graphics.Color
import androidx.compose.material3.dynamicLightColorScheme
import androidx.compose.material3.dynamicDarkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.sp

private val DarkColorPalette = androidx.compose.material3.darkColorScheme(
    primary = Color(0xFF6200EE),
    secondary = Color(0xFF03DAC6),
    background = Color(0xFF121212),
    surface = Color(0xFF1E1E1E),
    error = Color(0xFFCF6679),
    onPrimary = Color(0xFFFFFFFF),
    onSecondary = Color(0xFF000000),
    onBackground = Color(0xFFFFFFFF),
    onSurface = Color(0xFFFFFFFF),
    onError = Color(0xFF000000)
)

private val LightColorPalette = androidx.compose.material3.lightColorScheme(
    primary = Color(0xFF6200EE),
    secondary = Color(0xFF03DAC6),
    background = Color(0xFFFFFFFF),
    surface = Color(0xFFF5F5F5),
    error = Color(0xFFB3261E),
    onPrimary = Color(0xFFFFFFFF),
    onSecondary = Color(0xFF000000),
    onBackground = Color(0xFF000000),
    onSurface = Color(0xFF000000),
    onError = Color(0xFFFFFFFF)
)

@Composable
fun MarketerTheme(darkTheme: Boolean = isSystemInDarkTheme(), content: @Composable () -> Unit) {
    val colorScheme = if (darkTheme) DarkColorPalette else LightColorPalette
    MaterialTheme(
        colorScheme = colorScheme,
        typography = Typography(),
        content = content
    )
}

@Composable
private fun Typography() = androidx.compose.material3.Typography(
    displayLarge = TextStyle(fontSize = 57.sp, fontWeight = FontWeight.W400),
    displayMedium = TextStyle(fontSize = 45.sp, fontWeight = FontWeight.W400),
    displaySmall = TextStyle(fontSize = 36.sp, fontWeight = FontWeight.W400),
    headlineLarge = TextStyle(fontSize = 32.sp, fontWeight = FontWeight.W400),
    headlineMedium = TextStyle(fontSize = 28.sp, fontWeight = FontWeight.W400),
    headlineSmall = TextStyle(fontSize = 24.sp, fontWeight = FontWeight.W400),
    titleLarge = TextStyle(fontSize = 22.sp, fontWeight = FontWeight.W500),
    titleMedium = TextStyle(fontSize = 16.sp, fontWeight = FontWeight.W500),
    titleSmall = TextStyle(fontSize = 14.sp, fontWeight = FontWeight.W500),
    bodyLarge = TextStyle(fontSize = 16.sp, fontWeight = FontWeight.W400),
    bodyMedium = TextStyle(fontSize = 14.sp, fontWeight = FontWeight.W400),
    bodySmall = TextStyle(fontSize = 12.sp, fontWeight = FontWeight.W400),
    labelLarge = TextStyle(fontSize = 14.sp, fontWeight = FontWeight.W500),
    labelMedium = TextStyle(fontSize = 12.sp, fontWeight = FontWeight.W500),
    labelSmall = TextStyle(fontSize = 11.sp, fontWeight = FontWeight.W500)
)
