package com.tammtool.ordersapp.data.repository

import com.tammtool.ordersapp.data.local.GovernorateDao
import com.tammtool.ordersapp.data.model.Governorate
import kotlinx.coroutines.flow.Flow

class GovernorateRepository(private val governorateDao: GovernorateDao) {
    suspend fun insert(governorate: Governorate) = governorateDao.insert(governorate)
    suspend fun update(governorate: Governorate) = governorateDao.update(governorate)

    fun getAllActiveFlow(): Flow<List<Governorate>> = governorateDao.getAllActive()
    fun getAllFlow(): Flow<List<Governorate>> = governorateDao.getAll()
}
