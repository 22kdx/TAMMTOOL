package com.tammtool.ordersapp.data.repository

import com.tammtool.ordersapp.data.local.FinancialTransactionDao
import com.tammtool.ordersapp.data.model.FinancialTransaction
import kotlinx.coroutines.flow.Flow

class FinancialRepository(private val transactionDao: FinancialTransactionDao) {
    suspend fun insert(transaction: FinancialTransaction) = transactionDao.insert(transaction)
    suspend fun update(transaction: FinancialTransaction) = transactionDao.update(transaction)
    suspend fun getNetBalance(walletId: Int): Double = transactionDao.getNetBalance(walletId)
    suspend fun approve(id: Int, approvedBy: Int?, approvedAt: Long) = transactionDao.approve(id, approvedBy, approvedAt)
    suspend fun reject(id: Int) = transactionDao.reject(id)

    fun getByWalletFlow(walletId: Int): Flow<List<FinancialTransaction>> = transactionDao.getByWallet(walletId)
    fun getByUserFlow(userId: Int): Flow<List<FinancialTransaction>> = transactionDao.getByUser(userId)
    fun getAllPendingFlow(): Flow<List<FinancialTransaction>> = transactionDao.getAllPending()
}
