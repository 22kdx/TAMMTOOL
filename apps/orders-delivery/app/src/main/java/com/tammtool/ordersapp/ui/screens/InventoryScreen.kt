package com.tammtool.ordersapp.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.tammtool.ordersapp.ui.theme.OrdersTheme
import com.tammtool.ordersapp.ui.viewmodel.InventoryViewModel
import androidx.hilt.navigation.compose.hiltViewModel

@Composable
fun InventoryScreen(viewModel: InventoryViewModel = hiltViewModel()) {
    Column(modifier = Modifier.fillMaxSize()) {
        TopAppBar(
            title = { Text("إدارة المخزون") },
            colors = TopAppBarDefaults.mediumTopAppBarColors(
                containerColor = MaterialTheme.colorScheme.primaryContainer
            ),
            actions = {
                IconButton(onClick = { viewModel.loadMovements() }) {
                    Icon(Icons.Default.Refresh, contentDescription = "تحديث")
                }
            }
        )

        Text(
            text = "حركات المخزون",
            style = MaterialTheme.typography.titleMedium,
            modifier = Modifier.padding(16.dp)
        )
    }
}
