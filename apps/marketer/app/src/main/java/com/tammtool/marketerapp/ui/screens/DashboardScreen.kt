@file:OptIn(androidx.compose.material3.ExperimentalMaterial3Api::class)

package com.tammtool.marketerapp.ui.screens

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.LazyColumn

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.tammtool.marketerapp.ui.theme.MarketerTheme
import com.tammtool.marketerapp.ui.nav.AppRoutes

@Composable
fun DashboardScreen(onNavigateTo: (String) -> Unit) {
    Column(
        modifier = Modifier.fillMaxSize(),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        TopAppBar(
            title = { Text("لوحة التحكم - طلبات الأفغاني") },
            colors = TopAppBarDefaults.mediumTopAppBarColors(
                containerColor = MaterialTheme.colorScheme.primaryContainer
            )
        )

        LazyColumn(
            modifier = Modifier.fillMaxSize().padding(16.dp)
        ) {
            item {
                Text(
                    text = "إجراءات سريعة",
                    style = MaterialTheme.typography.titleMedium
                )
            }
            items(
                listOf(
                    QuickAction("طلباتي", "عرض وإدارة طلباتي", Icons.Default.List, AppRoutes.MY_ORDERS),
                    QuickAction("طلب جديد", "إنشاء طلب عميل جديد", Icons.Default.Add, AppRoutes.CREATE_ORDER),
                    QuickAction("عمولاتي", "عرض وحساب عمولاتي", Icons.Default.AttachMoney, AppRoutes.MY_COMMISSIONS),
                    QuickAction("إشعاراتي", "مراجعة التنبيهات والإشعارات", Icons.Default.Notifications, AppRoutes.MY_NOTIFICATIONS),
                    QuickAction("ملفي الشخصي", "بياناتي وحسابي", Icons.Default.Person, AppRoutes.PROFILE)
                )
            ) { action ->
                Card(
                    modifier = Modifier.fillMaxWidth().clickable { onNavigateTo(action.route) },
                    elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
                ) {
                    Row(
                        modifier = Modifier.padding(16.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            imageVector = action.icon,
                            contentDescription = action.title,
                            tint = MaterialTheme.colorScheme.primary,
                            modifier = Modifier.size(24.dp)
                        )
                        Spacer(modifier = Modifier.width(16.dp))
                        Column {
                            Text(text = action.title, style = MaterialTheme.typography.titleMedium)
                            Text(text = action.subtitle, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                        }
                    }
                }
            }
        }
    }
}

private data class QuickAction(
    val title: String,
    val subtitle: String,
    val icon: androidx.compose.ui.graphics.vector.ImageVector,
    val route: String
)
