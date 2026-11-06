package com.tammtool.marketerapp.ui.viewmodel

import kotlinx.coroutines.flow.first

import androidx.lifecycle.*
import com.tammtool.marketerapp.data.repository.MarketerOrderRepository
import com.tammtool.marketerapp.data.model.MarketerOrder
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject

@HiltViewModel
class OrderViewModel @Inject constructor(
    private val orderRepository: MarketerOrderRepository
) : BaseViewModel() {

    private val _orders = MutableLiveData<List<MarketerOrder>>(emptyList())
    val orders: LiveData<List<MarketerOrder>> = _orders

    private val _error = MutableLiveData<String?>(null)
    val error: LiveData<String?> = _error

    private val _loading = MutableLiveData(false)
    val loading: LiveData<Boolean> = _loading

    fun loadAllOrders() {
        _loading.value = true
        launchBlock {
            _orders.value = orderRepository.getAllOrdersFlow().first()
            _loading.value = false
        }
    }

    fun loadOrdersByStatus(status: MarketerOrder.OrderStatus) {
        _loading.value = true
        launchBlock {
            _orders.value = orderRepository.getByStatusFlow(status).first()
            _loading.value = false
        }
    }

    fun createOrder(order: MarketerOrder) {
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
}
