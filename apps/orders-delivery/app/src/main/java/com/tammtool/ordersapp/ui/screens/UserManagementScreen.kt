package com.tammtool.ordersapp.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.tammtool.ordersapp.data.model.User
import com.tammtool.ordersapp.ui.theme.OrdersTheme
import com.tammtool.ordersapp.ui.viewmodel.UserViewModel
import androidx.hilt.navigation.compose.hiltViewModel

@Composable
fun UserManagementScreen(viewModel: UserViewModel = hiltViewModel()) {
    val users by viewModel.users.collectAsState(initial = emptyList())

    Column(modifier = Modifier.fillMaxSize()) {
        TopAppBar(
            title = { Text("إدارة المستخدمين") },
            colors = TopAppBarDefaults.mediumTopAppBarColors(
                containerColor = MaterialTheme.colorScheme.primaryContainer
            ),
            actions = {
                IconButton(onClick = { viewModel.loadAllActiveUsers() }) {
                    Icon(Icons.Default.Refresh, contentDescription = "تحديث")
                }
            }
        )

        LazyColumn(
            modifier = Modifier.fillMaxSize().padding(8.dp)
        ) {
            items(users) { user ->
                UserCard(user = user)
            }
        }
    }
}

@Composable
private fun UserCard(user: User) {
    Card(
        modifier = Modifier.fillMaxWidth().padding(8.dp),
        elevation = 2.dp
    ) {
        Row(
            modifier = Modifier.padding(16.dp),
            verticalAlignment = androidx.compose.ui.Alignment.CenterVertically
        ) {
            Column {
                Text(text = user.fullName, style = MaterialTheme.typography.titleMedium)
                Text(text = user.phone, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
            Spacer(modifier = Modifier.weight(1f))
            Chip(
                label = { Text(user.role.name) },
                colors = ChipDefaults.colors(
                    containerColor = MaterialTheme.colorScheme.primaryContainer
                )
            )
            Icon(
                imageVector = if (user.isActive) Icons.Default.CheckCircle else Icons.Default.OfflineBolt,
                contentDescription = "الحالة",
                tint = if (user.isActive) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.outline
            )
        }
    }
}
