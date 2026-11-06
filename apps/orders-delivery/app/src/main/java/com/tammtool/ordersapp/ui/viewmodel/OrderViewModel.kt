package com.tammtool.ordersapp.ui.viewmodel

import kotlinx.coroutines.flow.first

import androidx.lifecycle.*
import com.tammtool.ordersapp.data.repository.OrderRepository
import com.tammtool.ordersapp.data.model.Order
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject

@HiltViewModel
class OrderViewModel @Inject constructor(
    private val orderRepository: OrderRepository
) : BaseViewModel() {

    private val _orders = MutableLiveData<List<Order>>(emptyList())
    val orders: LiveData<List<Order>> = _orders

    private val _error = MutableLiveData<String?>(null)
    val error: LiveData<String?> = _error

    private val _loading = MutableLiveData(false)
    val loading: LiveData<Boolean> = _loading

    fun loadOrdersByStatus(status: Order.OrderStatus) {
        _loading.value = true
        launchBlock {
            _orders.value = orderRepository.getByStatusFlow(status).first()
            _loading.value = false
        }
    }

    fun loadOrdersByCourier(courierId: Int) {
        _loading.value = true
        launchBlock {
            _orders.value = orderRepository.getByCourierFlow(courierId).first()
            _loading.value = false
        }
    }

    fun loadOrdersByMarketer(marketerId: Int) {
        _loading.value = true
        launchBlock {
            _orders.value = orderRepository.getByMarketerFlow(marketerId).first()
            _loading.value = false
        }
    }

    fun loadOrdersByCustomer(phone: String) {
        _loading.value = true
        launchBlock {
            _orders.value = orderRepository.getByCustomerPhoneFlow(phone).first()
            _loading.value = false
        }
    }

    fun loadAllOrders() {
        _loading.value = true
        launchBlock {
            _orders.value = orderRepository.getAllFlow().first()
            _loading.value = false
        }
    }

    fun createOrder(order: Order) {
        _loading.value = true
        _error.value = null
        launchBlock {
            try {
                orderRepository.insert(order)
                _orders.value = (_orders.value ?: emptyList()) + listOf(order)
            } catch (e: Exception) {
                _error.value = e.message
            }
            _loading.value = false
        }
    }

    fun updateOrderStatus(
        id: Int, status: Order.OrderStatus, courierId: Int?,
        deliveryCommission: Double, marketerCommission: Double
    ) {
        _loading.value = true
        launchBlock {
            orderRepository.updateStatusAndCourier(
                id, status, courierId, deliveryCommission, marketerCommission, System.currentTimeMillis()
            )
            loadAllOrders()
        }
    }

    fun updateOrderDelivery(
        id: Int, amountCollected: Double, imageUri: String, deliveredQuantity: Int
    ) {
        _loading.value = true
        launchBlock {
            orderRepository.updateDelivery(
                id, amountCollected, imageUri, deliveredQuantity, System.currentTimeMillis()
            )
            loadAllOrders()
        }
    }
}
