@file:OptIn(androidx.compose.material3.ExperimentalMaterial3Api::class)

package com.tammtool.marketerapp.ui.screens

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
import com.tammtool.marketerapp.ui.theme.MarketerTheme
import com.tammtool.marketerapp.ui.viewmodel.AuthViewModel

@Composable
fun LoginScreen(
    authViewModel: AuthViewModel,
    onLoginSuccess: () -> Unit
) {
    var phone by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    var fullName by remember { mutableStateOf("") }
    var showPassword by remember { mutableStateOf(false) }

    val loading by authViewModel.loading.observeAsState(false)
    val error by authViewModel.error.observeAsState()
    val user by authViewModel.user.observeAsState()
    val noAccounts by authViewModel.noAccounts.observeAsState(false)
    // أول تشغيل (قاعدة المستخدمين فارغة) ⇒ نفس الحقول تُستخدم لإنشاء الحساب بدل دخولٍ مستحيل
    var registerMode by remember { mutableStateOf(false) }
    val isFirstRun = noAccounts && registerMode

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
            text = "طلبات الأفغاني",
            style = MaterialTheme.typography.headlineMedium,
            color = MaterialTheme.colorScheme.primary,
            modifier = Modifier.padding(bottom = 8.dp)
        )
        Text(
            text = "تسجيل الدخول",
            style = MaterialTheme.typography.titleMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )

        Spacer(modifier = Modifier.height(32.dp))

        if (isFirstRun) {
            OutlinedTextField(
                value = fullName,
                onValueChange = { fullName = it },
                label = { Text("الاسم الكامل") },
                singleLine = true,
                modifier = Modifier.fillMaxWidth()
            )
            Spacer(modifier = Modifier.height(16.dp))
        }

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
            keyboardOptions = KeyboardOptions(keyboardType = if (showPassword) KeyboardType.Text else KeyboardType.Password),
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
                if (isFirstRun) authViewModel.register(fullName, phone, password)
                else authViewModel.login(phone, password)
            },
            enabled = !loading && phone.isNotEmpty() && password.isNotEmpty() &&
                (!isFirstRun || fullName.isNotEmpty()),
            modifier = Modifier.fillMaxWidth()
        ) {
            if (loading) {
                CircularProgressIndicator(modifier = Modifier.size(20.dp))
            } else {
                Text(if (isFirstRun) "إنشاء الحساب والدخول" else "تسجيل الدخول")
            }
        }

        if (noAccounts && !registerMode) {
            Spacer(modifier = Modifier.height(12.dp))
            OutlinedButton(
                onClick = { registerMode = true },
                modifier = Modifier.fillMaxWidth()
            ) {
                Text("لا يوجد حساب بعد — إنشاء أول حساب")
            }
        }

        Spacer(modifier = Modifier.height(16.dp))

        Text(
            text = "تطبيق مخصص للمسوقين - طلبات الأفغاني",
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}
