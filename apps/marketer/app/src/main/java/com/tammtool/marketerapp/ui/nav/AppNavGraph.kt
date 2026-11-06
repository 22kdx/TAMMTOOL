package com.tammtool.marketerapp.ui.nav

import androidx.compose.runtime.Composable

import androidx.navigation.NavHostController
import androidx.navigation.compose.composable
import androidx.navigation.compose.NavHost
import com.tammtool.marketerapp.ui.screens.*
import com.tammtool.marketerapp.ui.viewmodel.AuthViewModel
import com.tammtool.marketerapp.ui.viewmodel.OrderViewModel
import com.tammtool.marketerapp.ui.viewmodel.CommissionViewModel
import com.tammtool.marketerapp.ui.viewmodel.NotificationViewModel
import com.tammtool.marketerapp.ui.viewmodel.UserViewModel
import androidx.hilt.navigation.compose.hiltViewModel

object AppRoutes {
    const val LOGIN = "login"
    const val DASHBOARD = "dashboard"
    const val MY_ORDERS = "my_orders"
    const val ORDER_DETAIL = "order_detail"
    const val CREATE_ORDER = "create_order"
    const val MY_COMMISSIONS = "my_commissions"
    const val MY_NOTIFICATIONS = "my_notifications"
    const val PROFILE = "profile"
}

@Composable
fun AppNavGraph(
    navController: NavHostController,
    authViewModel: AuthViewModel = hiltViewModel()
) {
    NavHost(navController = navController, startDestination = AppRoutes.LOGIN) {
        composable(AppRoutes.LOGIN) {
            LoginScreen(authViewModel = authViewModel, onLoginSuccess = {
                navController.navigate(AppRoutes.DASHBOARD) {
                    popUpTo(AppRoutes.LOGIN) { inclusive = true }
                }
            })
        }

        composable(AppRoutes.DASHBOARD) {
            DashboardScreen(onNavigateTo = { route ->
                navController.navigate(route)
            })
        }

        composable(AppRoutes.MY_ORDERS) {
            MyOrdersScreen(viewModel = hiltViewModel(), onOrderSelected = { orderId ->
                navController.navigate(AppRoutes.ORDER_DETAIL + "/" + orderId)
            })
        }

        composable("${AppRoutes.ORDER_DETAIL}/{orderId}") {
            val orderId = it.arguments?.getString("orderId")?.toIntOrNull() ?: 0
            OrderDetailScreen(viewModel = hiltViewModel(), orderId = orderId, onBack = { navController.popBackStack() })
        }

        composable(AppRoutes.CREATE_ORDER) {
            CreateOrderScreen(viewModel = hiltViewModel(), onBack = { navController.popBackStack() })
        }

        composable(AppRoutes.MY_COMMISSIONS) {
            MyCommissionsScreen(viewModel = hiltViewModel())
        }

        composable(AppRoutes.MY_NOTIFICATIONS) {
            MyNotificationsScreen(viewModel = hiltViewModel())
        }

        composable(AppRoutes.PROFILE) {
            ProfileScreen(authViewModel = authViewModel, userViewModel = hiltViewModel())
        }
    }
}
