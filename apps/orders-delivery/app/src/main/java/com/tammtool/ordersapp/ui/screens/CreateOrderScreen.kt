@file:OptIn(androidx.compose.material3.ExperimentalMaterial3Api::class)

package com.tammtool.ordersapp.ui.screens

import androidx.compose.runtime.livedata.observeAsState
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.foundation.lazy.items

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.tammtool.ordersapp.data.model.Order
import com.tammtool.ordersapp.data.model.Product
import com.tammtool.ordersapp.ui.theme.OrdersTheme
import com.tammtool.ordersapp.ui.viewmodel.OrderViewModel
import com.tammtool.ordersapp.ui.viewmodel.ProductViewModel
import androidx.hilt.navigation.compose.hiltViewModel
import java.text.SimpleDateFormat
import java.util.*

@Composable
fun CreateOrderScreen(
    viewModel: OrderViewModel = hiltViewModel(),
    productViewModel: ProductViewModel = hiltViewModel(),
    onBack: () -> Unit
) {
    var customerName by remember { mutableStateOf("") }
    var customerPhone by remember { mutableStateOf("") }
    var governorate by remember { mutableStateOf("") }
    var address by remember { mutableStateOf("") }
    var websiteLink by remember { mutableStateOf("") }
    var product by remember { mutableStateOf("") }
    var quantity by remember { mutableStateOf("1") }
    var gift by remember { mutableStateOf("") }
    var giftQuantity by remember { mutableStateOf("0") }
    var agreedPrice by remember { mutableStateOf("0.0") }
    var deliveryDateTime by remember { mutableStateOf("") }

    val products by productViewModel.products.observeAsState(initial = emptyList())

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp)
    ) {
        TopAppBar(
            title = { Text("طلب جديد") },
            colors = TopAppBarDefaults.mediumTopAppBarColors(
                containerColor = MaterialTheme.colorScheme.primaryContainer
            ),
            navigationIcon = {
                IconButton(onClick = onBack) {
                    Icon(Icons.Default.ArrowBack, contentDescription = "رجوع")
                }
            }
        )

        LazyColumn(
            modifier = Modifier.fillMaxSize(),
            contentPadding = PaddingValues(8.dp)
        ) {
            item {
                OutlinedTextField(
                    value = customerName,
                    onValueChange = { customerName = it },
                    label = { Text("اسم العميل") },
                    modifier = Modifier.fillMaxWidth()
                )
            }
            item {
                OutlinedTextField(
                    value = customerPhone,
                    onValueChange = { customerPhone = it },
                    label = { Text("رقم هاتف العميل") },
                    modifier = Modifier.fillMaxWidth()
                )
            }
            item {
                OutlinedTextField(
                    value = governorate,
                    onValueChange = { governorate = it },
                    label = { Text("المحافظة") },
                    modifier = Modifier.fillMaxWidth()
                )
            }
            item {
                OutlinedTextField(
                    value = address,
                    onValueChange = { address = it },
                    label = { Text("العنوان التفصيلي أو رابط الموقع") },
                    modifier = Modifier.fillMaxWidth()
                )
            }
            item {
                OutlinedTextField(
                    value = websiteLink,
                    onValueChange = { websiteLink = it },
                    label = { Text("رابط الموقع (اختياري)") },
                    modifier = Modifier.fillMaxWidth()
                )
            }
            item {
                Text("المنتج", style = MaterialTheme.typography.titleMedium)
                Spacer(modifier = Modifier.height(8.dp))
            }
            items(products) { p ->
                ListItem(
                    modifier = Modifier.clickable { product = p.name },
                    headlineContent = { Text(p.name) },
                    supportingContent = { Text("السعر: ${p.basePrice} ريال") }
                )
            }
            item {
                OutlinedTextField(
                    value = quantity,
                    onValueChange = { quantity = it },
                    label = { Text("الكمية") },
                    modifier = Modifier.fillMaxWidth()
                )
            }
            item {
                OutlinedTextField(
                    value = gift,
                    onValueChange = { gift = it },
                    label = { Text("الهدية (اختياري)") },
                    modifier = Modifier.fillMaxWidth()
                )
            }
            item {
                OutlinedTextField(
                    value = giftQuantity,
                    onValueChange = { giftQuantity = it },
                    label = { Text("كمية الهدية") },
                    modifier = Modifier.fillMaxWidth()
                )
            }
            item {
                OutlinedTextField(
                    value = agreedPrice,
                    onValueChange = { agreedPrice = it },
                    label = { Text("السعر المتفق عليه") },
                    modifier = Modifier.fillMaxWidth()
                )
            }
            item {
                OutlinedTextField(
                    value = deliveryDateTime,
                    onValueChange = { deliveryDateTime = it },
                    label = { Text("تاريخ ووقت التسليم المطلوب") },
                    modifier = Modifier.fillMaxWidth()
                )
            }
            item {
                Spacer(modifier = Modifier.height(16.dp))
                Button(
                    onClick = {
                        val order = Order(
                            orderNumber = "ORD-${System.currentTimeMillis()}",
                            customerName = customerName,
                            customerPhone = customerPhone,
                            governorate = governorate,
                            address = address,
                            websiteLink = websiteLink,
                            product = product,
                            quantity = quantity.toIntOrNull() ?: 1,
                            gift = gift,
                            giftQuantity = giftQuantity.toIntOrNull() ?: 0,
                            agreedPrice = agreedPrice.toDoubleOrNull() ?: 0.0,
                            deliveryDateTime = SimpleDateFormat("yyyy-MM-dd HH:mm", Locale.getDefault()).parse(deliveryDateTime)?.time ?: System.currentTimeMillis(),
                            status = Order.OrderStatus.SUSPENDED
                        )
                        viewModel.createOrder(order)
                    },
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Text("إضافة الطلب")
                }
            }
        }
    }
}
