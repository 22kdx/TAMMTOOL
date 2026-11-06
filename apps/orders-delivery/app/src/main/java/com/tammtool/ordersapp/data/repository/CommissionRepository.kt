package com.tammtool.ordersapp.data.repository

import com.tammtool.ordersapp.data.local.CommissionDao
import com.tammtool.ordersapp.data.model.Commission
import kotlinx.coroutines.flow.Flow

class CommissionRepository(private val commissionDao: CommissionDao) {
    suspend fun insert(commission: Commission) = commissionDao.insert(commission)
    suspend fun update(commission: Commission) = commissionDao.update(commission)
    suspend fun getByOrder(orderId: Int): List<Commission> = commissionDao.getByOrder(orderId)
    suspend fun markPaid(id: Int, paidAt: Long, paidBy: Int?) = commissionDao.markPaid(id, paidAt, paidBy)
    suspend fun markCancelled(id: Int) = commissionDao.markCancelled(id)

    fun getDueByUserFlow(userId: Int): Flow<List<Commission>> = commissionDao.getDueByUser(userId)
    fun getByUserFlow(userId: Int): Flow<List<Commission>> = commissionDao.getByUser(userId)
}
