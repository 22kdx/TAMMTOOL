package com.tammtool.marketerapp.data.local

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.Query
import androidx.room.Update
import com.tammtool.marketerapp.data.model.MarketerNotification
import kotlinx.coroutines.flow.Flow

@Dao
interface MarketerNotificationDao {
    @Insert(onConflict = androidx.room.OnConflictStrategy.REPLACE)
    suspend fun insert(notification: MarketerNotification): Long

    @Update
    suspend fun update(notification: MarketerNotification)

    @Query("SELECT * FROM marketer_notifications ORDER BY created_at DESC")
    fun getAllNotifications(): Flow<List<MarketerNotification>>

    @Query("SELECT * FROM marketer_notifications WHERE is_read = 0 ORDER BY created_at DESC")
    fun getUnreadNotifications(): Flow<List<MarketerNotification>>

    @Query("UPDATE marketer_notifications SET is_read = 1 WHERE id = :id")
    suspend fun markRead(id: Int)

    @Query("UPDATE marketer_notifications SET is_read = 1")
    suspend fun markAllRead()
}
