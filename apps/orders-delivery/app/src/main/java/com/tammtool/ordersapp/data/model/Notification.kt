package com.tammtool.ordersapp.data.model

import androidx.room.Entity
import androidx.room.PrimaryKey
import androidx.room.ColumnInfo
import androidx.room.Index
import kotlinx.serialization.Serializable

@Serializable
@Entity(
    tableName = "notifications",
    indices = [Index(value = ["userId"]), Index(value = ["isRead"]), Index(value = ["createdAt"])]
)
data class Notification(
    @PrimaryKey(autoGenerate = true)
    @ColumnInfo(name = "id") val id: Int = 0,
    @ColumnInfo(name = "user_id") val userId: Int,
    @ColumnInfo(name = "title") val title: String,
    @ColumnInfo(name = "body") val body: String,
    @ColumnInfo(name = "channel") val channel: NotificationChannel = NotificationChannel.IN_APP,
    @ColumnInfo(name = "is_read") val isRead: Boolean = false,
    @ColumnInfo(name = "order_id") val orderId: Int = 0,
    @ColumnInfo(name = "created_at") val createdAt: Long = System.currentTimeMillis()
) {
    @Serializable
    enum class NotificationChannel {
        IN_APP, SMS, WHATSAPP
    }
}
