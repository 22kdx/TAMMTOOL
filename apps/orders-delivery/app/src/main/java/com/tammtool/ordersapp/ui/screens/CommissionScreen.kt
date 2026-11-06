package com.tammtool.ordersapp.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.tammtool.ordersapp.ui.theme.OrdersTheme
import com.tammtool.ordersapp.ui.viewmodel.CommissionViewModel
import androidx.hilt.navigation.compose.hiltViewModel

@Composable
fun CommissionScreen(viewModel: CommissionViewModel = hiltViewModel()) {
    Column(modifier = Modifier.fillMaxSize()) {
        TopAppBar(
            title = { Text("العمولات") },
            colors = TopAppBarDefaults.mediumTopAppBarColors(
                containerColor = MaterialTheme.colorScheme.primaryContainer
            ),
            actions = {
                IconButton(onClick = { }) {
                    Icon(Icons.Default.Refresh, contentDescription = "تحديث")
                }
            }
        )

        Text(
            text = "إدارة عمولات المناديب والمسوقين",
            style = MaterialTheme.typography.titleMedium,
            modifier = Modifier.padding(16.dp)
        )
    }
}
