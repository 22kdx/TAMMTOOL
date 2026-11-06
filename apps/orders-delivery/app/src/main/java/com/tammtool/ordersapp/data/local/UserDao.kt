package com.tammtool.ordersapp.data.local

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.Query
import androidx.room.Update
import androidx.room.Delete
import com.tammtool.ordersapp.data.model.User
import kotlinx.coroutines.flow.Flow

@Dao
interface UserDao {
    @Insert(onConflict = androidx.room.OnConflictStrategy.REPLACE)
    suspend fun insert(user: User): Long

    @Update
    suspend fun update(user: User)

    @Delete
    suspend fun delete(user: User)

    @Query("SELECT * FROM users WHERE id = :id")
    suspend fun getById(id: Int): User?

    @Query("SELECT * FROM users WHERE phone = :phone")
    suspend fun getByPhone(phone: String): User?

    @Query("SELECT * FROM users WHERE role = :role AND is_active = 1")
    fun getByRole(role: User.UserRole): Flow<List<User>>

    @Query("SELECT * FROM users WHERE is_active = 1")
    fun getAllActive(): Flow<List<User>>

    @Query("SELECT * FROM users")
    fun getAll(): Flow<List<User>>

    @Query("UPDATE users SET is_active = 0 WHERE id = :id")
    suspend fun deactivate(id: Int)

    @Query("SELECT COUNT(*) FROM users WHERE role = :role")
    suspend fun countByRole(role: User.UserRole): Int
}
