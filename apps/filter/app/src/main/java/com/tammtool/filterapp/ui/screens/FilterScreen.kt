package com.tammtool.filterapp.ui.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.FilterChip
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Slider
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.camera.view.PreviewView
import androidx.compose.ui.viewinterop.AndroidView
import com.tammtool.filterapp.R
import com.tammtool.filterapp.domain.Filter

/**
 * الشاشة: معاينة CameraX + شريط فلاتر + منزلق الشدة.
 *
 * لا يُطبَّق RenderEffect هنا مباشرة: يُمرَّر عبر [modifier] من المستدعي، حتى يبقى
 * التكوين قابلاً للاختبار/اللقطة بلا كاميرا حقيقية.
 */
@Composable
fun FilterScreen(
    filters: List<Filter>,
    selectedId: String,
    intensity: Float,
    error: String?,
    onSelect: (Filter) -> Unit,
    onIntensity: (Float) -> Unit,
    modifier: Modifier = Modifier
) {
    Column(modifier = modifier.fillMaxSize()) {
        AndroidView(
            factory = { ctx -> PreviewView(ctx).apply { scaleType = PreviewView.ScaleType.FILL_CENTER } },
            modifier = Modifier.fillMaxWidth().aspectRatio(3f / 4f)
        )

        if (error != null) {
            Text(error, color = MaterialTheme.colorScheme.error, modifier = Modifier.padding(16.dp))
        }

        LazyRow(
            modifier = Modifier.fillMaxWidth().padding(vertical = 8.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            contentPadding = androidx.compose.foundation.layout.PaddingValues(horizontal = 12.dp)
        ) {
            items(filters, key = { it.id }) { filter ->
                FilterChip(
                    selected = filter.id == selectedId,
                    onClick = { onSelect(filter) },
                    label = { Text(stringResource(filter.labelRes)) }
                )
            }
        }

        Row(modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp), verticalAlignment =
            androidx.compose.ui.Alignment.CenterVertically) {
            Text(stringResource(R.string.intensity), style = MaterialTheme.typography.labelMedium)
            Slider(
                value = intensity,
                onValueChange = onIntensity,
                modifier = Modifier.padding(start = 12.dp)
            )
        }
    }
}
