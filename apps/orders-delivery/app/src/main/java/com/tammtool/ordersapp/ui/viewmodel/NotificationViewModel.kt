package com.tammtool.ordersapp.ui.viewmodel

import kotlinx.coroutines.flow.first

import androidx.lifecycle.*
import com.tammtool.ordersapp.data.repository.NotificationRepository
import com.tammtool.ordersapp.data.model.Notification
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject

@HiltViewModel
class NotificationViewModel @Inject constructor(
    private val notificationRepository: NotificationRepository
) : BaseViewModel() {

    private val _notifications = MutableLiveData<List<Notification>>(emptyList())
    val notifications: LiveData<List<Notification>> = _notifications

    private val _unread = MutableLiveData<List<Notification>>(emptyList())
    val unreadNotifications: LiveData<List<Notification>> = _unread

    fun loadNotificationsForUser(userId: Int) {
        launchBlock {
            _notifications.value = notificationRepository.getByUserFlow(userId).first()
            _unread.value = notificationRepository.getUnreadFlow(userId).first()
        }
    }

    fun createNotification(notification: Notification) {
        launchBlock {
            try {
                notificationRepository.insert(notification)
            } catch (e: Exception) {
                // Error handling
            }
        }
    }

    fun markAsRead(id: Int) {
        launchBlock {
            notificationRepository.markRead(id)
        }
    }
}
