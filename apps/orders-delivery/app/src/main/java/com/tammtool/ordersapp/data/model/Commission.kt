package com.tammtool.ordersapp.data.model

import androidx.room.Entity
import androidx.room.PrimaryKey
import androidx.room.ColumnInfo
import androidx.room.Index
import androidx.room.ForeignKey
import kotlinx.serialization.Serializable

@Serializable
@Entity(
    tableName = "commissions",
    indices = [Index(value = ["userId"]), Index(value = ["orderId"]), Index(value = ["status"])],
    foreignKeys = [
        ForeignKey(
            entity = User::class,
            parentColumns = ["id"],
            childColumns = ["userId"],
            onDelete = ForeignKey.CASCADE
        ),
        ForeignKey(
            entity = Order::class,
            parentColumns = ["id"],
            childColumns = ["orderId"],
            onDelete = ForeignKey.CASCADE
        )
    ]
)
data class Commission(
    @PrimaryKey(autoGenerate = true)
    @ColumnInfo(name = "id") val id: Int = 0,
    @ColumnInfo(name = "user_id") val userId: Int,
    @ColumnInfo(name = "order_id") val orderId: Int,
    @ColumnInfo(name = "commission_type") val commissionType: CommissionType,
    @ColumnInfo(name = "amount") val amount: Double,
    @ColumnInfo(name = "status") val status: CommissionStatus = CommissionStatus.DUE,
    @ColumnInfo(name = "paid_at") val paidAt: Long = 0,
    @ColumnInfo(name = "paid_by") val paidBy: Int? = null,
    @ColumnInfo(name = "created_at") val createdAt: Long = System.currentTimeMillis()
) {
    @Serializable
    enum class CommissionType {
        COURIER, MARKETER
    }

    @Serializable
    enum class CommissionStatus {
        DUE, PAID, CANCELLED
    }
}
