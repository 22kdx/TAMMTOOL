package com.tammtool.ordersapp.ui.screens

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.tammtool.ordersapp.data.model.Order
import com.tammtool.ordersapp.ui.theme.OrdersTheme
import com.tammtool.ordersapp.ui.viewmodel.OrderViewModel
import androidx.hilt.navigation.compose.hiltViewModel

@Composable
fun OrderDetailScreen(
    viewModel: OrderViewModel = hiltViewModel(),
    orderId: Int,
    onBack: () -> Unit
) {
    val order = remember { mutableStateOf<Order?>(null) }
    val loading by viewModel.loading.collectAsState(initial = false)

    if (!loading && order.value == null) {
        viewModel.loadOrdersByStatus(Order.OrderStatus.SUSPENDED)
    }

    Column(modifier = Modifier.fillMaxSize()) {
        TopAppBar(
            title = { Text("تفاصيل الطلب") },
            colors = TopAppBarDefaults.mediumTopAppBarColors(
                containerColor = MaterialTheme.colorScheme.primaryContainer
            ),
            navigationIcon = {
                IconButton(onClick = onBack) {
                    Icon(Icons.Default.ArrowBack, contentDescription = "رجوع")
                }
            }
        )

        if (loading) {
            CircularProgressIndicator(modifier = Modifier.align(Alignment.Center))
        } else {
            val currentOrder = order.value
            if (currentOrder != null) {
                Column(
                    modifier = Modifier.fillMaxSize().padding(16.dp)
                ) {
                    Text(
                        text = "طلب #${currentOrder.orderNumber}",
                        style = MaterialTheme.typography.headlineSmall
                    )
                    Spacer(modifier = Modifier.height(16.dp))
                    DetailRow(label = "اسم العميل", value = currentOrder.customerName)
                    DetailRow(label = "الهاتف", value = currentOrder.customerPhone)
                    DetailRow(label = "المحافظة", value = currentOrder.governorate)
                    DetailRow(label = "العنوان", value = currentOrder.address)
                    DetailRow(label = "المنتج", value = currentOrder.product)
                    DetailRow(label = "الكمية", value = "${currentOrder.quantity}")
                    DetailRow(label = "السعر", value = "${currentOrder.agreedPrice} ريال")
                    DetailRow(label = "الحالة", value = currentOrder.status.name)
                    Spacer(modifier = Modifier.height(24.dp))
                }
            }
        }
    }
}

@Composable
private fun DetailRow(label: String, value: String) {
    Row(
        modifier = Modifier.fillMaxWidth().padding(vertical = 4.dp),
        verticalAlignment = androidx.compose.ui.Alignment.CenterVertically
    ) {
        Text(
            text = label,
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier.weight(0.4f)
        )
        Text(
            text = value,
            style = MaterialTheme.typography.bodyMedium.copy(fontWeight = androidx.compose.ui.text.FontWeight.W500)
        )
    }
}
