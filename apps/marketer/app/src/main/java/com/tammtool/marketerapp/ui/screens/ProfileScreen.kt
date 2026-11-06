@file:OptIn(androidx.compose.material3.ExperimentalMaterial3Api::class)

package com.tammtool.marketerapp.ui.screens

import androidx.compose.runtime.livedata.observeAsState
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.ui.Alignment

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.tammtool.marketerapp.ui.theme.MarketerTheme
import com.tammtool.marketerapp.ui.viewmodel.AuthViewModel
import com.tammtool.marketerapp.ui.viewmodel.UserViewModel
import androidx.hilt.navigation.compose.hiltViewModel

@Composable
fun ProfileScreen(
    authViewModel: AuthViewModel = hiltViewModel(),
    userViewModel: UserViewModel = hiltViewModel()
) {
    val user by userViewModel.user.observeAsState(initial = null)

    Column(modifier = Modifier.fillMaxSize().padding(16.dp)) {
        TopAppBar(
            title = { Text("ملفي الشخصي") },
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
                Text(text = "طلبات الأفغاني - المسوق", style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.primary)
                Text(text = "الرصيد: ${u.walletBalance} ريال", style = MaterialTheme.typography.bodyMedium)
                Text(text = "سقف الدين: ${u.debtLimit} ريال", style = MaterialTheme.typography.bodyMedium)
                Text(text = "نسبة العمولة: ${u.commissionRate}%", style = MaterialTheme.typography.bodyMedium)
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
