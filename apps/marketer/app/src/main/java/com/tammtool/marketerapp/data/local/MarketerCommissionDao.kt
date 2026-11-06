package com.tammtool.marketerapp.data.local

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.Query
import androidx.room.Update
import com.tammtool.marketerapp.data.model.MarketerCommission
import kotlinx.coroutines.flow.Flow

@Dao
interface MarketerCommissionDao {
    @Insert(onConflict = androidx.room.OnConflictStrategy.REPLACE)
    suspend fun insert(commission: MarketerCommission): Long

    @Update
    suspend fun update(commission: MarketerCommission)

    @Query("SELECT * FROM marketer_commissions ORDER BY created_at DESC")
    fun getAllCommissions(): Flow<List<MarketerCommission>>

    @Query("SELECT * FROM marketer_commissions WHERE status = :status ORDER BY created_at DESC")
    fun getByStatus(status: MarketerCommission.CommissionStatus): Flow<List<MarketerCommission>>

    @Query("SELECT SUM(amount) FROM marketer_commissions WHERE status = :status")
    suspend fun getTotalByStatus(status: MarketerCommission.CommissionStatus): Double

    @Query("UPDATE marketer_commissions SET status = 'PAID', paid_at = :paidAt WHERE id = :id")
    suspend fun markPaid(id: Int, paidAt: Long)
}
