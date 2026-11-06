package com.tammtool.ordersapp.data.repository

import com.tammtool.ordersapp.data.local.InventoryDao
import com.tammtool.ordersapp.data.model.InventoryMovement
import kotlinx.coroutines.flow.Flow

class InventoryRepository(private val inventoryDao: InventoryDao) {
    suspend fun insert(movement: InventoryMovement) = inventoryDao.insert(movement)
    fun getByProductFlow(productId: Int): Flow<List<InventoryMovement>> = inventoryDao.getByProduct(productId)
    fun getAllFlow(): Flow<List<InventoryMovement>> = inventoryDao.getAll()
    fun getStockSummaryFlow(): Flow<List<InventoryDao.StockSummary>> = inventoryDao.getStockSummary()
}
