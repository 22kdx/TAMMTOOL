package com.tammtool.marketerapp.data.repository

import com.tammtool.marketerapp.data.local.MarketerNotificationDao
import com.tammtool.marketerapp.data.model.MarketerNotification
import kotlinx.coroutines.flow.Flow

class MarketerNotificationRepository(private val notificationDao: MarketerNotificationDao) {
    suspend fun insert(notification: MarketerNotification) = notificationDao.insert(notification)
    suspend fun update(notification: MarketerNotification) = notificationDao.update(notification)
    suspend fun markRead(id: Int) = notificationDao.markRead(id)
    suspend fun markAllRead() = notificationDao.markAllRead()

    fun getAllNotificationsFlow(): Flow<List<MarketerNotification>> = notificationDao.getAllNotifications()
    fun getUnreadNotificationsFlow(): Flow<List<MarketerNotification>> = notificationDao.getUnreadNotifications()
}
