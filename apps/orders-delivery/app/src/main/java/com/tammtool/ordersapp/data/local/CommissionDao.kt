package com.tammtool.ordersapp.data.local

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.Query
import androidx.room.Update
import com.tammtool.ordersapp.data.model.Commission
import kotlinx.coroutines.flow.Flow

@Dao
interface CommissionDao {
    @Insert(onConflict = androidx.room.OnConflictStrategy.REPLACE)
    suspend fun insert(commission: Commission): Long

    @Update
    suspend fun update(commission: Commission)

    @Query("SELECT * FROM commissions WHERE user_id = :userId AND status = 'DUE'")
    fun getDueByUser(userId: Int): Flow<List<Commission>>

    @Query("SELECT * FROM commissions WHERE order_id = :orderId")
    suspend fun getByOrder(orderId: Int): List<Commission>

    @Query("SELECT * FROM commissions WHERE user_id = :userId ORDER BY created_at DESC")
    fun getByUser(userId: Int): Flow<List<Commission>>

    @Query("UPDATE commissions SET status = 'PAID', paid_at = :paidAt, paid_by = :paidBy WHERE id = :id")
    suspend fun markPaid(id: Int, paidAt: Long, paidBy: Int?)

    @Query("UPDATE commissions SET status = 'CANCELLED' WHERE id = :id")
    suspend fun markCancelled(id: Int)
}
