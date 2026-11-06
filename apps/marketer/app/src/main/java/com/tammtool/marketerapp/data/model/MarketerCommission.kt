package com.tammtool.marketerapp.data.model

import androidx.room.Entity
import androidx.room.PrimaryKey
import androidx.room.ColumnInfo
import androidx.room.Index
import kotlinx.serialization.Serializable

@Serializable
@Entity(
    tableName = "marketer_commissions",
    indices = [Index(value = ["status"]), Index(value = ["createdAt"])]
)
data class MarketerCommission(
    @PrimaryKey(autoGenerate = true)
    @ColumnInfo(name = "id") val id: Int = 0,
    @ColumnInfo(name = "order_id") val orderId: Int,
    @ColumnInfo(name = "order_number") val orderNumber: String,
    @ColumnInfo(name = "commission_type") val commissionType: String = "marketer",
    @ColumnInfo(name = "amount") val amount: Double,
    @ColumnInfo(name = "status") val status: CommissionStatus = CommissionStatus.DUE,
    @ColumnInfo(name = "paid_at") val paidAt: Long = 0,
    @ColumnInfo(name = "created_at") val createdAt: Long = System.currentTimeMillis()
) {
    @Serializable
    enum class CommissionStatus {
        DUE, PAID, CANCELLED
    }
}
