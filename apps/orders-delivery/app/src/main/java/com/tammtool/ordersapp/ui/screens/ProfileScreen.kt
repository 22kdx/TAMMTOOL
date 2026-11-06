package com.tammtool.ordersapp.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.tammtool.ordersapp.ui.theme.OrdersTheme
import com.tammtool.ordersapp.ui.viewmodel.AuthViewModel
import androidx.hilt.navigation.compose.hiltViewModel

@Composable
fun ProfileScreen(authViewModel: AuthViewModel = hiltViewModel()) {
    val user by authViewModel.user.collectAsState(initial = null)

    Column(modifier = Modifier.fillMaxSize().padding(16.dp)) {
        TopAppBar(
            title = { Text("الملف الشخصي") },
            colors = TopAppBarDefaults.mediumTopAppBarColors(
                containerColor = MaterialTheme.colorScheme.primaryContainer
            )
        )

        user?.let { u ->
            Column(
                modifier = Modifier.fillMaxWidth(),
                horizontalAlignment = androidx.compose.ui.Alignment.CenterHorizontally
            ) {
                Icon(
                    imageVector = Icons.Default.Person,
                    contentDescription = "المستخدم",
                    modifier = Modifier.size(64.dp),
                    tint = MaterialTheme.colorScheme.primary
                )
                Spacer(modifier = Modifier.height(16.dp))
                Text(text = u.fullName, style = MaterialTheme.typography.headlineSmall)
                Spacer(modifier = Modifier.height(8.dp))
                Text(text = u.phone, style = MaterialTheme.typography.bodyLarge)
                Text(text = u.role.name, style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.primary)
                Text(text = "الرصيد: ${u.walletBalance} ريال", style = MaterialTheme.typography.bodyMedium)
                Spacer(modifier = Modifier.height(24.dp))
                Button(
                    onClick = { authViewModel.logout() },
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Text("تسجيل الخروج")
                }
            }
        }
    }
}
