package com.tammtool.ordersapp.ui.nav

import androidx.compose.runtime.Composable

import androidx.navigation.NavHostController
import androidx.navigation.compose.composable
import androidx.navigation.compose.NavHost
import androidx.navigation.navArgument
import com.tammtool.ordersapp.ui.screens.*
import com.tammtool.ordersapp.ui.viewmodel.AuthViewModel
import com.tammtool.ordersapp.ui.viewmodel.OrderViewModel
import com.tammtool.ordersapp.ui.viewmodel.UserViewModel
import com.tammtool.ordersapp.ui.viewmodel.ProductViewModel
import com.tammtool.ordersapp.ui.viewmodel.InventoryViewModel
import com.tammtool.ordersapp.ui.viewmodel.MissionViewModel
import com.tammtool.ordersapp.ui.viewmodel.CommissionViewModel
import com.tammtool.ordersapp.ui.viewmodel.FinancialViewModel
import com.tammtool.ordersapp.ui.viewmodel.NotificationViewModel
import androidx.hilt.navigation.compose.hiltViewModel

object AppRoutes {
    const val LOGIN = "login"
    const val DASHBOARD = "dashboard"
    const val ORDERS = "orders"
    const val ORDER_DETAIL = "order_detail"
    const val CREATE_ORDER = "create_order"
    const val USERS = "users"
    const val PRODUCTS = "products"
    const val INVENTORY = "inventory"
    const val MISSIONS = "missions"
    const val COMMISSIONS = "commissions"
    const val FINANCIAL = "financial"
    const val NOTIFICATIONS = "notifications"
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

        composable(AppRoutes.ORDERS) {
            OrderListScreen(
                viewModel = hiltViewModel(),
                onOrderSelected = { orderId ->
                    navController.navigate(AppRoutes.ORDER_DETAIL + "/" + orderId)
                },
                onCreateOrder = {
                    navController.navigate(AppRoutes.CREATE_ORDER)
                }
            )
        }

        composable("${AppRoutes.ORDER_DETAIL}/{orderId}") {
            val orderId = it.arguments?.getString("orderId")?.toIntOrNull() ?: 0
            OrderDetailScreen(
                viewModel = hiltViewModel(),
                orderId = orderId,
                onBack = { navController.popBackStack() }
            )
        }

        composable(AppRoutes.CREATE_ORDER) {
            CreateOrderScreen(viewModel = hiltViewModel(), onBack = { navController.popBackStack() })
        }

        composable(AppRoutes.USERS) {
            UserManagementScreen(viewModel = hiltViewModel())
        }

        composable(AppRoutes.PRODUCTS) {
            ProductManagementScreen(viewModel = hiltViewModel())
        }

        composable(AppRoutes.INVENTORY) {
            InventoryScreen(viewModel = hiltViewModel())
        }

        composable(AppRoutes.MISSIONS) {
            MissionScreen(viewModel = hiltViewModel())
        }

        composable(AppRoutes.COMMISSIONS) {
            CommissionScreen(viewModel = hiltViewModel())
        }

        composable(AppRoutes.FINANCIAL) {
            FinancialScreen(viewModel = hiltViewModel())
        }

        composable(AppRoutes.NOTIFICATIONS) {
            NotificationScreen(viewModel = hiltViewModel())
        }

        composable(AppRoutes.PROFILE) {
            ProfileScreen(authViewModel = authViewModel)
        }
    }
}
