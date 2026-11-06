package com.tammtool.ordersapp.data.local

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.Query
import androidx.room.Update
import androidx.room.Delete
import com.tammtool.ordersapp.data.model.Product
import kotlinx.coroutines.flow.Flow

@Dao
interface ProductDao {
    @Insert(onConflict = androidx.room.OnConflictStrategy.REPLACE)
    suspend fun insert(product: Product): Long

    @Update
    suspend fun update(product: Product)

    @Delete
    suspend fun delete(product: Product)

    @Query("SELECT * FROM products WHERE id = :id")
    suspend fun getById(id: Int): Product?

    @Query("SELECT * FROM products WHERE is_active = 1")
    fun getAllActive(): Flow<List<Product>>

    @Query("SELECT * FROM products WHERE is_gift = 1 AND is_active = 1")
    fun getAllGifts(): Flow<List<Product>>

    @Query("SELECT * FROM products")
    fun getAll(): Flow<List<Product>>

    @Query("UPDATE products SET is_active = 0 WHERE id = :id")
    suspend fun deactivate(id: Int)
}
