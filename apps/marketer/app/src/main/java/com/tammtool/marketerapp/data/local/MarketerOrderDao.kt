package com.tammtool.marketerapp.data.local

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.Query
import androidx.room.Update
import com.tammtool.marketerapp.data.model.MarketerOrder
import kotlinx.coroutines.flow.Flow

@Dao
interface MarketerOrderDao {
    @Insert(onConflict = androidx.room.OnConflictStrategy.REPLACE)
    suspend fun insert(order: MarketerOrder): Long

    @Update
    suspend fun update(order: MarketerOrder)

    @Query("SELECT * FROM marketer_orders WHERE id = :id")
    suspend fun getById(id: Int): MarketerOrder?

    @Query("SELECT * FROM marketer_orders WHERE order_number = :orderNumber")
    suspend fun getByOrderNumber(orderNumber: String): MarketerOrder?

    @Query("SELECT * FROM marketer_orders ORDER BY created_at DESC")
    fun getAllOrders(): Flow<List<MarketerOrder>>

    @Query("SELECT * FROM marketer_orders WHERE status = :status ORDER BY created_at DESC")
    fun getByStatus(status: MarketerOrder.OrderStatus): Flow<List<MarketerOrder>>

    @Query("SELECT * FROM marketer_orders WHERE customer_phone = :phone ORDER BY created_at DESC")
    fun getByCustomerPhone(phone: String): Flow<List<MarketerOrder>>

    @Query("""
        UPDATE marketer_orders 
        SET status = :status, updated_at = :updatedAt
        WHERE id = :id
    """)
    suspend fun updateStatus(id: Int, status: MarketerOrder.OrderStatus, updatedAt: Long)

    @Query("SELECT COUNT(*) FROM marketer_orders")
    suspend fun countAll(): Int

    @Query("SELECT COUNT(*) FROM marketer_orders WHERE status = :status")
    suspend fun countByStatus(status: MarketerOrder.OrderStatus): Int
}
