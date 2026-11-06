package com.tammtool.ordersapp.data.local

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.Query
import androidx.room.Update
import androidx.room.Delete
import com.tammtool.ordersapp.data.model.Order
import kotlinx.coroutines.flow.Flow

@Dao
interface OrderDao {
    @Insert(onConflict = androidx.room.OnConflictStrategy.REPLACE)
    suspend fun insert(order: Order): Long

    @Update
    suspend fun update(order: Order)

    @Delete
    suspend fun delete(order: Order)

    @Query("SELECT * FROM orders WHERE id = :id")
    suspend fun getById(id: Int): Order?

    @Query("SELECT * FROM orders WHERE order_number = :orderNumber")
    suspend fun getByOrderNumber(orderNumber: String): Order?

    @Query("SELECT * FROM orders WHERE status = :status")
    fun getByStatus(status: Order.OrderStatus): Flow<List<Order>>

    @Query("SELECT * FROM orders WHERE courier_id = :courierId")
    fun getByCourier(courierId: Int): Flow<List<Order>>

    @Query("SELECT * FROM orders WHERE marketer_id = :marketerId")
    fun getByMarketer(marketerId: Int): Flow<List<Order>>

    @Query("SELECT * FROM orders WHERE customer_phone = :phone")
    fun getByCustomerPhone(phone: String): Flow<List<Order>>

    @Query("SELECT * FROM orders ORDER BY created_at DESC")
    fun getAll(): Flow<List<Order>>

    @Query("""
        UPDATE orders 
        SET status = :status, courier_id = :courierId, 
            delivery_commission = :deliveryCommission, marketer_commission = :marketerCommission,
            updated_at = :updatedAt
        WHERE id = :id
    """)
    suspend fun updateStatusAndCourier(
        id: Int,
        status: Order.OrderStatus,
        courierId: Int?,
        deliveryCommission: Double,
        marketerCommission: Double,
        updatedAt: Long
    )

    @Query("""
        UPDATE orders 
        SET amount_collected = :amountCollected, amount_collected_image = :imageUri,
            delivered_quantity = :deliveredQuantity, updated_at = :updatedAt
        WHERE id = :id
    """)
    suspend fun updateDelivery(
        id: Int,
        amountCollected: Double,
        imageUri: String,
        deliveredQuantity: Int,
        updatedAt: Long
    )

    @Query("SELECT COUNT(*) FROM orders WHERE status = :status")
    suspend fun countByStatus(status: Order.OrderStatus): Int
}
