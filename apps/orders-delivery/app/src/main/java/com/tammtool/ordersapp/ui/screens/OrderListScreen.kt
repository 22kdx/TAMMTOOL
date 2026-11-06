@file:OptIn(androidx.compose.material3.ExperimentalMaterial3Api::class)

package com.tammtool.ordersapp.ui.screens

import androidx.compose.runtime.livedata.observeAsState
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.foundation.lazy.items
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.Alignment

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.tammtool.ordersapp.data.model.Order
import com.tammtool.ordersapp.ui.theme.OrdersTheme
import com.tammtool.ordersapp.ui.viewmodel.OrderViewModel
import androidx.hilt.navigation.compose.hiltViewModel

@Composable
fun OrderListScreen(
    viewModel: OrderViewModel = hiltViewModel(),
    onOrderSelected: (Int) -> Unit,
    onCreateOrder: () -> Unit
) {
    val orders by viewModel.orders.observeAsState(initial = emptyList())
    val loading by viewModel.loading.observeAsState(initial = false)

    Column(modifier = Modifier.fillMaxSize()) {
        TopAppBar(
            title = { Text("الطلبات") },
            colors = TopAppBarDefaults.mediumTopAppBarColors(
                containerColor = MaterialTheme.colorScheme.primaryContainer
            ),
            actions = {
                IconButton(onClick = { viewModel.loadAllOrders() }) {
                    Icon(Icons.Default.Refresh, contentDescription = "تحديث")
                }
                IconButton(onClick = onCreateOrder) {
                    Icon(Icons.Default.Add, contentDescription = "طلب جديد")
                }
            }
        )

        if (loading) {
            CircularProgressIndicator(modifier = Modifier.align(Alignment.CenterHorizontally))
        } else {
            LazyColumn(
                modifier = Modifier.fillMaxSize().padding(8.dp)
            ) {
                items(orders) { order ->
                    OrderCard(
                        order = order,
                        onClick = { onOrderSelected(order.id) }
                    )
                }
            }
        }
    }
}

@Composable
private fun OrderCard(order: Order, onClick: () -> Unit) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(8.dp),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text(
                    text = "طلب #${order.orderNumber}",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = androidx.compose.ui.text.font.FontWeight.Bold
                )
                SuggestionChip(onClick = {},
                    label = { Text(order.status.name) },
                    colors = SuggestionChipDefaults.suggestionChipColors(
                        containerColor = statusColor(order.status).copy(alpha = 0.2f)
                    )
                )
            }
            Spacer(modifier = Modifier.height(8.dp))
            Text(text = order.customerName, style = MaterialTheme.typography.bodyMedium)
            Text(text = order.customerPhone, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
            Text(text = order.governorate, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
            Spacer(modifier = Modifier.height(8.dp))
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text(
                    text = "السعر: ${order.agreedPrice} ريال",
                    style = MaterialTheme.typography.bodyMedium.copy(fontWeight = androidx.compose.ui.text.font.FontWeight.W500)
                )
                Text(
                    text = "الكمية: ${order.quantity}",
                    style = MaterialTheme.typography.bodySmall
                )
            }
        }
    }
}

@Composable
private fun statusColor(status: Order.OrderStatus): androidx.compose.ui.graphics.Color = when (status) {
    Order.OrderStatus.SUSPENDED -> MaterialTheme.colorScheme.secondary
    Order.OrderStatus.IN_COMMUNICATION -> MaterialTheme.colorScheme.secondary
    Order.OrderStatus.COURIER_APPROVED -> Color(0xFF1976D2)
    Order.OrderStatus.AWAITING_PRICE_APPROVAL -> Color(0xFFFFA000)
    Order.OrderStatus.AWAITING_QUANTITY_APPROVAL -> Color(0xFFFFA000)
    Order.OrderStatus.POSTPONED -> Color(0xFF9E9E9E)
    Order.OrderStatus.CANCELLED -> MaterialTheme.colorScheme.error
    Order.OrderStatus.DELIVERED -> Color(0xFF4CAF50)
    Order.OrderStatus.COMPLETED -> Color(0xFF2E7D32)
}
