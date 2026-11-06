package com.tammtool.ordersapp.data.local

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.Query
import com.tammtool.ordersapp.data.model.InventoryMovement
import kotlinx.coroutines.flow.Flow

@Dao
interface InventoryDao {
    @Insert(onConflict = androidx.room.OnConflictStrategy.REPLACE)
    suspend fun insert(movement: InventoryMovement): Long

    @Query("SELECT * FROM inventory_movements WHERE product_id = :productId ORDER BY created_at DESC")
    fun getByProduct(productId: Int): Flow<List<InventoryMovement>>

    @Query("SELECT * FROM inventory_movements ORDER BY created_at DESC")
    fun getAll(): Flow<List<InventoryMovement>>

    @Query("""
        SELECT product_id, SUM(CASE WHEN movement_type = 'IN' THEN quantity 
             WHEN movement_type = 'MISSION_ASSIGN' THEN -quantity 
             WHEN movement_type = 'OUT' THEN -quantity 
             WHEN movement_type = 'MISSION_RETURN' THEN quantity 
             ELSE 0 END) as net_quantity
        FROM inventory_movements 
        GROUP BY product_id
    """)
    fun getStockSummary(): Flow<List<StockSummary>>

    data class StockSummary(
        val productId: Int,
        val netQuantity: Int
    )
}
