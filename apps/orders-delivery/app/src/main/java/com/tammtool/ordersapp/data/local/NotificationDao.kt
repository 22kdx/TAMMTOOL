package com.tammtool.ordersapp.data.local

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.Query
import androidx.room.Update
import com.tammtool.ordersapp.data.model.Notification
import kotlinx.coroutines.flow.Flow

@Dao
interface NotificationDao {
    @Insert(onConflict = androidx.room.OnConflictStrategy.REPLACE)
    suspend fun insert(notification: Notification): Long

    @Update
    suspend fun update(notification: Notification)

    @Query("SELECT * FROM notifications WHERE user_id = :userId ORDER BY created_at DESC")
    fun getByUser(userId: Int): Flow<List<Notification>>

    @Query("SELECT * FROM notifications WHERE user_id = :userId AND is_read = 0 ORDER BY created_at DESC")
    fun getUnread(userId: Int): Flow<List<Notification>>

    @Query("UPDATE notifications SET is_read = 1 WHERE id = :id")
    suspend fun markRead(id: Int)

    @Query("UPDATE notifications SET is_read = 1 WHERE user_id = :userId")
    suspend fun markAllRead(userId: Int)
}
