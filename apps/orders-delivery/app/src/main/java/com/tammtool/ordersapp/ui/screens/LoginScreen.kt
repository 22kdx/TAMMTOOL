@file:OptIn(androidx.compose.material3.ExperimentalMaterial3Api::class)

package com.tammtool.ordersapp.ui.screens

import androidx.compose.runtime.livedata.observeAsState
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import com.tammtool.ordersapp.data.model.User
import com.tammtool.ordersapp.ui.theme.OrdersTheme
import com.tammtool.ordersapp.ui.viewmodel.AuthViewModel

@Composable
fun LoginScreen(
    authViewModel: AuthViewModel,
    onLoginSuccess: () -> Unit
) {
    var phone by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    var fullName by remember { mutableStateOf("") }
    var showPassword by remember { mutableStateOf(false) }
    var registerMode by remember { mutableStateOf(false) }

    val loading by authViewModel.loading.observeAsState(false)
    val error by authViewModel.error.observeAsState()
    val user by authViewModel.user.observeAsState()
    val noAccounts by authViewModel.noAccounts.observeAsState(false)

    LaunchedEffect(Unit) { authViewModel.refreshFirstRunState() }

    if (user != null) {
        onLoginSuccess()
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(24.dp),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            text = "تطبيق إدارة الطلبات والمناديب",
            style = MaterialTheme.typography.headlineMedium,
            color = MaterialTheme.colorScheme.primary,
            modifier = Modifier.padding(bottom = 8.dp)
        )
        Text(
            text = if (registerMode) "إنشاء حساب" else "تسجيل الدخول",
            style = MaterialTheme.typography.titleMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )

        Spacer(modifier = Modifier.height(32.dp))

        OutlinedTextField(
            value = phone,
            onValueChange = { phone = it },
            label = { Text("رقم الهاتف") },
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
            singleLine = true,
            modifier = Modifier.fillMaxWidth(),
            trailingIcon = {
                if (phone.isNotEmpty()) {
                    IconButton(onClick = { phone = "" }) {
                        Icon(Icons.Default.Close, contentDescription = "مسح")
                    }
                }
            }
        )

        Spacer(modifier = Modifier.height(16.dp))

        OutlinedTextField(
            value = password,
            onValueChange = { password = it },
            label = { Text("كلمة المرور") },
            visualTransformation = if (showPassword) androidx.compose.ui.text.input.VisualTransformation.None else androidx.compose.ui.text.input.PasswordVisualTransformation(),
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.VisiblePassword),
            singleLine = true,
            modifier = Modifier.fillMaxWidth(),
            trailingIcon = {
                IconButton(onClick = { showPassword = !showPassword }) {
                    Icon(
                        imageVector = if (showPassword) Icons.Default.VisibilityOff else Icons.Default.Visibility,
                        contentDescription = "إظهار/إخفاء كلمة المرور"
                    )
                }
            }
        )

        if (registerMode) {
            OutlinedTextField(
                value = fullName,
                onValueChange = { fullName = it },
                label = { Text("الاسم الكامل") },
                singleLine = true,
                modifier = Modifier.fillMaxWidth()
            )
            Spacer(modifier = Modifier.height(12.dp))
            Text(
                text = if (noAccounts)
                    "أول حساب في هذا الجهاز ⇒ دور «مدير النظام» تلقائياً."
                else "سيُنشأ الحساب بدور «إدارة» ريثما يمنحه مدير النظام الأدوار الأخرى.",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }

        if (error != null) {
            Text(
                text = error.orEmpty(),
                color = MaterialTheme.colorScheme.error,
                modifier = Modifier.padding(top = 8.dp)
            )
        }

        Spacer(modifier = Modifier.height(24.dp))

        Button(
            onClick = {
                if (registerMode) {
                    val role = if (noAccounts) User.UserRole.SYSTEM_MANAGER else User.UserRole.ADMINISTRATION
                    authViewModel.register(fullName, phone, password, role)
                } else {
                    authViewModel.login(phone, password)
                }
            },
            enabled = !loading && phone.isNotEmpty() && password.isNotEmpty() &&
                (!registerMode || fullName.isNotEmpty()),
            modifier = Modifier.fillMaxWidth()
        ) {
            if (loading) {
                CircularProgressIndicator(modifier = Modifier.size(20.dp))
            } else {
                Text(if (registerMode) "إنشاء الحساب والدخول" else "تسجيل الدخول")
            }
        }

        Spacer(modifier = Modifier.height(16.dp))

        // الزر كان فارغاً («navigate to register - simplified») ⇒ يُفعَّل كوضع إنشاء حساب داخل نفس الشاشة
        OutlinedButton(
            onClick = { registerMode = !registerMode },
            modifier = Modifier.fillMaxWidth()
        ) {
            Text(if (registerMode) "إلغاء وإنشاء أول حساب" else "إنشاء حساب جديد")
        }
    }
}
