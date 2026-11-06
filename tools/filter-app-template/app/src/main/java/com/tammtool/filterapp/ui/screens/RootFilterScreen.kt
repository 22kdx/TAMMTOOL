package com.tammtool.filterapp.ui.screens

import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.lifecycle.compose.observeAsState
import com.tammtool.filterapp.ui.FilterViewModel

/** طبقة فاصلة حتى تبقى الشاشة قابلة للاختبار بلا كاميرا (تُمرّر ViewModel وهمية في الاختبارات). */
@Composable
fun RootFilterScreen(viewModel: FilterViewModel) {
    val selected by viewModel.selected.observeAsState()
    val filters by viewModel.filters.observeAsState(emptyList())
    val intensity by viewModel.intensity.observeAsState(0.5f)
    val error by viewModel.error.observeAsState()
    FilterScreen(
        filters = filters,
        selectedId = selected?.id.orEmpty(),
        intensity = intensity,
        error = error,
        onSelect = { f -> viewModel.select(f) },
        onIntensity = { viewModel.setIntensity(it) }
    )
}
