package com.tammtool.marketerapp.data.repository

import com.tammtool.marketerapp.data.local.MarketerCommissionDao
import com.tammtool.marketerapp.data.model.MarketerCommission
import kotlinx.coroutines.flow.Flow

class MarketerCommissionRepository(private val commissionDao: MarketerCommissionDao) {
    suspend fun insert(commission: MarketerCommission) = commissionDao.insert(commission)
    suspend fun update(commission: MarketerCommission) = commissionDao.update(commission)
    suspend fun markPaid(id: Int, paidAt: Long) = commissionDao.markPaid(id, paidAt)

    fun getAllCommissionsFlow(): Flow<List<MarketerCommission>> = commissionDao.getAllCommissions()
    fun getByStatusFlow(status: MarketerCommission.CommissionStatus): Flow<List<MarketerCommission>> =
        commissionDao.getByStatus(status)
    suspend fun getTotalByStatus(status: MarketerCommission.CommissionStatus): Double =
        commissionDao.getTotalByStatus(status)
}
