package com.tammtool.ordersapp.ui.screens

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.tammtool.ordersapp.ui.theme.OrdersTheme
import com.tammtool.ordersapp.ui.nav.AppRoutes
import com.tammtool.ordersapp.data.model.User

@Composable
fun DashboardScreen(onNavigateTo: (String) -> Unit) {
    Column(
        modifier = Modifier.fillMaxSize(),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        TopAppBar(
            title = { Text("لوحة التحكم") },
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
                    QuickAction("الطلبات", "إدارة ومراجعة الطلبات", Icons.Default.List, AppRoutes.ORDERS),
                    QuickAction("المستخدمين", "إدارة الحسابات والصلاحيات", Icons.Default.People, AppRoutes.USERS),
                    QuickAction("المنتجات", "إدارة الكتالوج والهدايا", Icons.Default.Store, AppRoutes.PRODUCTS),
                    QuickAction("المخزون", "مراقبة المخزون والحركات", Icons.Default.Inventory, AppRoutes.INVENTORY),
                    QuickAction("المناديب", "إدارة العهديات والمهام", Icons.Default.DeliveryDining, AppRoutes.MISSIONS),
                    QuickAction("العمولات", "إدارة وحساب العمولات", Icons.Default.AttachMoney, AppRoutes.COMMISSIONS),
                    QuickAction("المالية", "المحفظات والمعاملات", Icons.Default.AccountBalanceWallet, AppRoutes.FINANCIAL),
                    QuickAction("الإشعارات", "مراجعة الإشعارات والتنبيهات", Icons.Default.Notifications, AppRoutes.NOTIFICATIONS),
                    QuickAction("الملف الشخصي", "بيانات الحساب والإعدادات", Icons.Default.Person, AppRoutes.PROFILE)
                )
            ) { action ->
                Card(
                    modifier = Modifier.fillMaxWidth().clickable { onNavigateTo(action.route) },
                    elevation = 2.dp
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
