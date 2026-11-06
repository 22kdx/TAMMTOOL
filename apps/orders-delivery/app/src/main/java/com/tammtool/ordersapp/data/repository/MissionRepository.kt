package com.tammtool.ordersapp.data.repository

import com.tammtool.ordersapp.data.local.MissionDao
import com.tammtool.ordersapp.data.model.Mission
import kotlinx.coroutines.flow.Flow

class MissionRepository(private val missionDao: MissionDao) {
    suspend fun insert(mission: Mission) = missionDao.insert(mission)
    suspend fun update(mission: Mission) = missionDao.update(mission)
    suspend fun getById(id: Int): Mission? = missionDao.getById(id)
    suspend fun markReturned(id: Int, returnedAt: Long) = missionDao.markReturned(id, returnedAt)
    suspend fun updateRemaining(id: Int, qty: Int) = missionDao.updateRemaining(id, qty)

    fun getActiveByCourierFlow(courierId: Int): Flow<List<Mission>> = missionDao.getActiveByCourier(courierId)
    fun getByCourierFlow(courierId: Int): Flow<List<Mission>> = missionDao.getByCourier(courierId)
}
