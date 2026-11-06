package com.tammtool.marketerapp.ui.viewmodel

import androidx.lifecycle.*
import com.tammtool.marketerapp.data.repository.MarketerNotificationRepository
import com.tammtool.marketerapp.data.model.MarketerNotification
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject

@HiltViewModel
class NotificationViewModel @Inject constructor(
    private val notificationRepository: MarketerNotificationRepository
) : BaseViewModel() {

    private val _notifications = MutableLiveData<List<MarketerNotification>>(emptyList())
    val notifications: LiveData<List<MarketerNotification>> = _notifications

    private val _unread = MutableLiveData<List<MarketerNotification>>(emptyList())
    val unreadNotifications: LiveData<List<MarketerNotification>> = _unread

    fun loadNotifications() {
        launchBlock {
            _notifications.value = notificationRepository.getAllNotificationsFlow().first()
            _unread.value = notificationRepository.getUnreadNotificationsFlow().first()
        }
    }

    fun markAsRead(id: Int) {
        launchBlock {
            notificationRepository.markRead(id)
        }
    }
}
