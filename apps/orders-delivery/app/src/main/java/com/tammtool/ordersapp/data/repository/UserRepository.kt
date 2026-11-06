package com.tammtool.ordersapp.data.repository

import androidx.lifecycle.LiveData
import com.tammtool.ordersapp.data.local.AppDatabase
import com.tammtool.ordersapp.data.local.UserDao
import com.tammtool.ordersapp.data.model.User
import kotlinx.coroutines.flow.Flow

class UserRepository(private val userDao: UserDao) {
    suspend fun insert(user: User) = userDao.insert(user)
    suspend fun update(user: User) = userDao.update(user)
    suspend fun deactivate(id: Int) = userDao.deactivate(id)
    suspend fun getById(id: Int): User? = userDao.getById(id)
    suspend fun getByPhone(phone: String): User? = userDao.getByPhone(phone)
    suspend fun countByRole(role: User.UserRole): Int = userDao.countByRole(role)

    fun getByRoleFlow(role: User.UserRole): Flow<List<User>> = userDao.getByRole(role)
    fun getAllActiveFlow(): Flow<List<User>> = userDao.getAllActive()
    fun getAllFlow(): Flow<List<User>> = userDao.getAll()
}
