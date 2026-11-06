package com.tammtool.ordersapp.data.local

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.Query
import androidx.room.Update
import com.tammtool.ordersapp.data.model.FinancialTransaction
import kotlinx.coroutines.flow.Flow

@Dao
interface FinancialTransactionDao {
    @Insert(onConflict = androidx.room.OnConflictStrategy.REPLACE)
    suspend fun insert(transaction: FinancialTransaction): Long

    @Update
    suspend fun update(transaction: FinancialTransaction)

    @Query("SELECT * FROM financial_transactions WHERE wallet_id = :walletId ORDER BY created_at DESC")
    fun getByWallet(walletId: Int): Flow<List<FinancialTransaction>>

    @Query("SELECT * FROM financial_transactions WHERE user_id = :userId ORDER BY created_at DESC")
    fun getByUser(userId: Int): Flow<List<FinancialTransaction>>

    @Query("SELECT * FROM financial_transactions WHERE status = 'PENDING'")
    fun getAllPending(): Flow<List<FinancialTransaction>>

    @Query("""
        SELECT SUM(CASE WHEN transaction_type = 'CREDIT' THEN amount ELSE -amount END) as net_balance
        FROM financial_transactions 
        WHERE wallet_id = :walletId AND status = 'APPROVED'
    """)
    suspend fun getNetBalance(walletId: Int): Double

    @Query("UPDATE financial_transactions SET status = 'APPROVED', approved_by = :approvedBy, approved_at = :approvedAt WHERE id = :id")
    suspend fun approve(id: Int, approvedBy: Int?, approvedAt: Long)

    @Query("UPDATE financial_transactions SET status = 'REJECTED' WHERE id = :id")
    suspend fun reject(id: Int)
}
