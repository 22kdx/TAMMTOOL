package com.tammtool.marketerapp.data.repository

import com.tammtool.marketerapp.data.local.MarketerUserDao
import com.tammtool.marketerapp.data.model.MarketerUser
import kotlinx.coroutines.flow.Flow

class MarketerUserRepository(private val userDao: MarketerUserDao) {
    suspend fun insert(user: MarketerUser) = userDao.insert(user)
    suspend fun update(user: MarketerUser) = userDao.update(user)
    suspend fun getByPhone(phone: String): MarketerUser? = userDao.getByPhone(phone)
    suspend fun getById(id: Int): MarketerUser? = userDao.getById(id)
    fun getActiveUserFlow(): Flow<MarketerUser?> = userDao.getActiveUser()
    suspend fun count(): Int = userDao.count()
}
