package com.tammtool.ordersapp.data.model

import androidx.room.Entity
import androidx.room.PrimaryKey
import androidx.room.ColumnInfo
import androidx.room.Index
import androidx.room.ForeignKey
import kotlinx.serialization.Serializable

@Serializable
@Entity(
    tableName = "missions",
    indices = [Index(value = ["courierId"]), Index(value = ["status"])],
    foreignKeys = [
        ForeignKey(
            entity = User::class,
            parentColumns = ["id"],
            childColumns = ["courierId"],
            onDelete = ForeignKey.CASCADE
        )
    ]
)
data class Mission(
    @PrimaryKey(autoGenerate = true)
    @ColumnInfo(name = "id") val id: Int = 0,
    @ColumnInfo(name = "courier_id") val courierId: Int,
    @ColumnInfo(name = "courier_name") val courierName: String,
    @ColumnInfo(name = "product_id") val productId: Int,
    @ColumnInfo(name = "product_name") val productName: String,
    @ColumnInfo(name = "quantity_assigned") val quantityAssigned: Int,
    @ColumnInfo(name = "quantity_remaining") val quantityRemaining: Int,
    @ColumnInfo(name = "status") val status: MissionStatus = MissionStatus.ACTIVE,
    @ColumnInfo(name = "assigned_at") val assignedAt: Long = System.currentTimeMillis(),
    @ColumnInfo(name = "returned_at") val returnedAt: Long = 0,
    @ColumnInfo(name = "notes") val notes: String = ""
) {
    @Serializable
    enum class MissionStatus {
        ACTIVE, RETURNED, COMPLETED
    }
}
