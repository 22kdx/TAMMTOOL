package com.tammtool.ordersapp.data.local

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.Query
import androidx.room.Update
import com.tammtool.ordersapp.data.model.Governorate
import kotlinx.coroutines.flow.Flow

@Dao
interface GovernorateDao {
    @Insert(onConflict = androidx.room.OnConflictStrategy.REPLACE)
    suspend fun insert(governorate: Governorate): Long

    @Update
    suspend fun update(governorate: Governorate)

    @Query("SELECT * FROM governorates WHERE is_active = 1")
    fun getAllActive(): Flow<List<Governorate>>

    @Query("SELECT * FROM governorates")
    fun getAll(): Flow<List<Governorate>>
}
