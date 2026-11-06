package com.tammtool.ordersapp.data.repository

import com.tammtool.ordersapp.data.local.ProductDao
import com.tammtool.ordersapp.data.model.Product
import kotlinx.coroutines.flow.Flow

class ProductRepository(private val productDao: ProductDao) {
    suspend fun insert(product: Product) = productDao.insert(product)
    suspend fun update(product: Product) = productDao.update(product)
    suspend fun getById(id: Int): Product? = productDao.getById(id)
    suspend fun deactivate(id: Int) = productDao.deactivate(id)

    fun getAllActiveFlow(): Flow<List<Product>> = productDao.getAllActiveFlow()
    fun getAllGiftsFlow(): Flow<List<Product>> = productDao.getAllGiftsFlow()
    fun getAllFlow(): Flow<List<Product>> = productDao.getAll()
}
