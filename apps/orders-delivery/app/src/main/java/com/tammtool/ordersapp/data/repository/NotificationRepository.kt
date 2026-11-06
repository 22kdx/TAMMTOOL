package com.tammtool.ordersapp.data.repository

import com.tammtool.ordersapp.data.local.NotificationDao
import com.tammtool.ordersapp.data.model.Notification
import kotlinx.coroutines.flow.Flow

class NotificationRepository(private val notificationDao: NotificationDao) {
    suspend fun insert(notification: Notification) = notificationDao.insert(notification)
    suspend fun update(notification: Notification) = notificationDao.update(notification)
    suspend fun markRead(id: Int) = notificationDao.markRead(id)
    suspend fun markAllRead(userId: Int) = notificationDao.markAllRead(userId)

    fun getByUserFlow(userId: Int): Flow<List<Notification>> = notificationDao.getByUser(userId)
    fun getUnreadFlow(userId: Int): Flow<List<Notification>> = notificationDao.getUnread(userId)
}
