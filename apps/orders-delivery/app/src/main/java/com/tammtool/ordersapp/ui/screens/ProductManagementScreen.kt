@file:OptIn(androidx.compose.material3.ExperimentalMaterial3Api::class)

package com.tammtool.ordersapp.ui.screens

import androidx.compose.runtime.livedata.observeAsState
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.foundation.lazy.items
import androidx.compose.ui.Alignment

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.tammtool.ordersapp.data.model.Product
import com.tammtool.ordersapp.ui.theme.OrdersTheme
import com.tammtool.ordersapp.ui.viewmodel.ProductViewModel
import androidx.hilt.navigation.compose.hiltViewModel

@Composable
fun ProductManagementScreen(viewModel: ProductViewModel = hiltViewModel()) {
    val products by viewModel.products.observeAsState(initial = emptyList())

    Column(modifier = Modifier.fillMaxSize()) {
        TopAppBar(
            title = { Text("المنتجات والهدايا") },
            colors = TopAppBarDefaults.mediumTopAppBarColors(
                containerColor = MaterialTheme.colorScheme.primaryContainer
            ),
            actions = {
                IconButton(onClick = { viewModel.loadAllProducts() }) {
                    Icon(Icons.Default.Refresh, contentDescription = "تحديث")
                }
            }
        )

        LazyColumn(
            modifier = Modifier.fillMaxSize().padding(8.dp)
        ) {
            items(products) { product ->
                ProductCard(product = product)
            }
        }
    }
}

@Composable
private fun ProductCard(product: Product) {
    Card(
        modifier = Modifier.fillMaxWidth().padding(8.dp),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Row(
            modifier = Modifier.padding(16.dp),
            verticalAlignment = androidx.compose.ui.Alignment.CenterVertically
        ) {
            Column {
                Text(text = product.name, style = MaterialTheme.typography.titleMedium)
                Text(text = "${product.basePrice} ريال", style = MaterialTheme.typography.bodyMedium.copy(fontWeight = androidx.compose.ui.text.font.FontWeight.W500))
                Text(text = "الوحدة: ${product.unit}", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                if (product.isGift) {
                    Text(text = "هدية", style = MaterialTheme.typography.bodySmall.copy(color = MaterialTheme.colorScheme.secondary))
                }
            }
            Spacer(modifier = Modifier.weight(1f))
            SuggestionChip(onClick = {},
                label = { Text(if (product.isActive) "نشط" else "غير نشط") },
                colors = SuggestionChipDefaults.suggestionChipColors(
                    containerColor = if (product.isActive) MaterialTheme.colorScheme.primaryContainer else MaterialTheme.colorScheme.surfaceContainer
                )
            )
        }
    }
}
