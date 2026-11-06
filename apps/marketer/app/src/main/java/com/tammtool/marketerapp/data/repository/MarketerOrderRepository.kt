package com.tammtool.marketerapp.data.repository

import com.tammtool.marketerapp.data.local.MarketerOrderDao
import com.tammtool.marketerapp.data.model.MarketerOrder
import kotlinx.coroutines.flow.Flow

class MarketerOrderRepository(private val orderDao: MarketerOrderDao) {
    suspend fun insert(order: MarketerOrder) = orderDao.insert(order)
    suspend fun update(order: MarketerOrder) = orderDao.update(order)
    suspend fun getById(id: Int): MarketerOrder? = orderDao.getById(id)
    suspend fun getByOrderNumber(orderNumber: String): MarketerOrder? = orderDao.getByOrderNumber(orderNumber)
    suspend fun updateStatus(id: Int, status: MarketerOrder.OrderStatus, updatedAt: Long) =
        orderDao.updateStatus(id, status, updatedAt)
    suspend fun countAll(): Int = orderDao.countAll()
    suspend fun countByStatus(status: MarketerOrder.OrderStatus): Int = orderDao.countByStatus(status)

    fun getAllOrdersFlow(): Flow<List<MarketerOrder>> = orderDao.getAllOrders()
    fun getByStatusFlow(status: MarketerOrder.OrderStatus): Flow<List<MarketerOrder>> = orderDao.getByStatus(status)
    fun getByCustomerPhoneFlow(phone: String): Flow<List<MarketerOrder>> = orderDao.getByCustomerPhone(phone)
}
