package com.tammtool.ordersapp.data.local

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.Query
import androidx.room.Update
import com.tammtool.ordersapp.data.model.Mission
import kotlinx.coroutines.flow.Flow

@Dao
interface MissionDao {
    @Insert(onConflict = androidx.room.OnConflictStrategy.REPLACE)
    suspend fun insert(mission: Mission): Long

    @Update
    suspend fun update(mission: Mission)

    @Query("SELECT * FROM missions WHERE courier_id = :courierId AND status = 'ACTIVE'")
    fun getActiveByCourier(courierId: Int): Flow<List<Mission>>

    @Query("SELECT * FROM missions WHERE id = :id")
    suspend fun getById(id: Int): Mission?

    @Query("SELECT * FROM missions WHERE courier_id = :courierId ORDER BY assigned_at DESC")
    fun getByCourier(courierId: Int): Flow<List<Mission>>

    @Query("UPDATE missions SET status = 'RETURNED', returned_at = :returnedAt WHERE id = :id")
    suspend fun markReturned(id: Int, returnedAt: Long)

    @Query("UPDATE missions SET quantity_remaining = :qty WHERE id = :id")
    suspend fun updateRemaining(id: Int, qty: Int)
}
