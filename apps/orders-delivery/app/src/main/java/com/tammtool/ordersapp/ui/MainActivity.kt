package com.tammtool.ordersapp.ui

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.navigation.NavHostController
import androidx.navigation.compose.rememberNavController
import com.tammtool.ordersapp.ui.nav.AppNavGraph
import com.tammtool.ordersapp.ui.theme.OrdersTheme
import com.tammtool.ordersapp.ui.viewmodel.AuthViewModel
import androidx.hilt.navigation.compose.hiltViewModel

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            OrdersTheme {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = androidx.compose.material3.LocalColorScheme.current.background
                ) {
                    val navController = rememberNavController()
                    val authViewModel: AuthViewModel = hiltViewModel()
                    AppNavGraph(navController = navController, authViewModel = authViewModel)
                }
            }
        }
    }
}
