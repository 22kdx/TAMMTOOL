package com.tammtool.marketerapp.ui.screens

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.tammtool.marketerapp.data.model.MarketerOrder
import com.tammtool.marketerapp.ui.theme.MarketerTheme
import com.tammtool.marketerapp.ui.viewmodel.OrderViewModel
import androidx.hilt.navigation.compose.hiltViewModel
import java.text.SimpleDateFormat
import java.util.*

@Composable
fun CreateOrderScreen(
    viewModel: OrderViewModel = hiltViewModel(),
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

        androidx.compose.foundation.layout.Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(8.dp)
                .verticalScroll(rememberScrollState())
        ) {
            OutlinedTextField(
                value = customerName,
                onValueChange = { customerName = it },
                label = { Text("اسم العميل") },
                modifier = Modifier.fillMaxWidth()
            )
            Spacer(modifier = Modifier.height(16.dp))

            OutlinedTextField(
                value = customerPhone,
                onValueChange = { customerPhone = it },
                label = { Text("رقم هاتف العميل") },
                modifier = Modifier.fillMaxWidth()
            )
            Spacer(modifier = Modifier.height(16.dp))

            OutlinedTextField(
                value = governorate,
                onValueChange = { governorate = it },
                label = { Text("المحافظة") },
                modifier = Modifier.fillMaxWidth()
            )
            Spacer(modifier = Modifier.height(16.dp))

            OutlinedTextField(
                value = address,
                onValueChange = { address = it },
                label = { Text("العنوان التفصيلي أو رابط الموقع") },
                modifier = Modifier.fillMaxWidth()
            )
            Spacer(modifier = Modifier.height(16.dp))

            OutlinedTextField(
                value = websiteLink,
                onValueChange = { websiteLink = it },
                label = { Text("رابط الموقع (اختياري)") },
                modifier = Modifier.fillMaxWidth()
            )
            Spacer(modifier = Modifier.height(16.dp))

            OutlinedTextField(
                value = product,
                onValueChange = { product = it },
                label = { Text("المنتج") },
                modifier = Modifier.fillMaxWidth()
            )
            Spacer(modifier = Modifier.height(16.dp))

            OutlinedTextField(
                value = quantity,
                onValueChange = { quantity = it },
                label = { Text("الكمية") },
                modifier = Modifier.fillMaxWidth()
            )
            Spacer(modifier = Modifier.height(16.dp))

            OutlinedTextField(
                value = gift,
                onValueChange = { gift = it },
                label = { Text("الهدية (اختياري)") },
                modifier = Modifier.fillMaxWidth()
            )
            Spacer(modifier = Modifier.height(16.dp))

            OutlinedTextField(
                value = giftQuantity,
                onValueChange = { giftQuantity = it },
                label = { Text("كمية الهدية") },
                modifier = Modifier.fillMaxWidth()
            )
            Spacer(modifier = Modifier.height(16.dp))

            OutlinedTextField(
                value = agreedPrice,
                onValueChange = { agreedPrice = it },
                label = { Text("السعر المتفق عليه") },
                modifier = Modifier.fillMaxWidth()
            )
            Spacer(modifier = Modifier.height(16.dp))

            OutlinedTextField(
                value = deliveryDateTime,
                onValueChange = { deliveryDateTime = it },
                label = { Text("تاريخ ووقت التسليم المطلوب") },
                modifier = Modifier.fillMaxWidth()
            )
            Spacer(modifier = Modifier.height(24.dp))

            Button(
                onClick = {
                    val order = MarketerOrder(
                        orderNumber = "MKT-${System.currentTimeMillis()}",
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
                        status = MarketerOrder.OrderStatus.SUSPENDED
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
