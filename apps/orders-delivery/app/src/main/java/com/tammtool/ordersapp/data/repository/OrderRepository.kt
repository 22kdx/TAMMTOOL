package com.tammtool.ordersapp.data.repository

import com.tammtool.ordersapp.data.local.OrderDao
import com.tammtool.ordersapp.data.model.Order
import kotlinx.coroutines.flow.Flow

class OrderRepository(private val orderDao: OrderDao) {
    suspend fun insert(order: Order) = orderDao.insert(order)
    suspend fun update(order: Order) = orderDao.update(order)
    suspend fun getById(id: Int): Order? = orderDao.getById(id)
    suspend fun getByOrderNumber(orderNumber: String): Order? = orderDao.getByOrderNumber(orderNumber)
    suspend fun updateStatusAndCourier(
        id: Int, status: Order.OrderStatus, courierId: Int?,
        deliveryCommission: Double, marketerCommission: Double, updatedAt: Long
    ) = orderDao.updateStatusAndCourier(id, status, courierId, deliveryCommission, marketerCommission, updatedAt)

    suspend fun updateDelivery(
        id: Int, amountCollected: Double, imageUri: String,
        deliveredQuantity: Int, updatedAt: Long
    ) = orderDao.updateDelivery(id, amountCollected, imageUri, deliveredQuantity, updatedAt)

    suspend fun countByStatus(status: Order.OrderStatus): Int = orderDao.countByStatus(status)

    fun getByStatusFlow(status: Order.OrderStatus): Flow<List<Order>> = orderDao.getByStatus(status)
    fun getByCourierFlow(courierId: Int): Flow<List<Order>> = orderDao.getByCourier(courierId)
    fun getByMarketerFlow(marketerId: Int): Flow<List<Order>> = orderDao.getByMarketer(marketerId)
    fun getByCustomerPhoneFlow(phone: String): Flow<List<Order>> = orderDao.getByCustomerPhone(phone)
    fun getAllFlow(): Flow<List<Order>> = orderDao.getAll()
}
