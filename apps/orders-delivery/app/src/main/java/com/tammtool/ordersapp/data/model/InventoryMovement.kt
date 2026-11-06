package com.tammtool.ordersapp.data.model

import androidx.room.Entity
import androidx.room.PrimaryKey
import androidx.room.ColumnInfo
import androidx.room.Index
import androidx.room.ForeignKey
import kotlinx.serialization.Serializable

@Serializable
@Entity(
    tableName = "inventory_movements",
    indices = [Index(value = ["productId"]), Index(value = ["createdAt"])],
    foreignKeys = [
        ForeignKey(
            entity = Product::class,
            parentColumns = ["id"],
            childColumns = ["productId"],
            onDelete = ForeignKey.CASCADE
        )
    ]
)
data class InventoryMovement(
    @PrimaryKey(autoGenerate = true)
    @ColumnInfo(name = "id") val id: Int = 0,
    @ColumnInfo(name = "product_id") val productId: Int,
    @ColumnInfo(name = "movement_type") val movementType: MovementType,
    @ColumnInfo(name = "quantity") val quantity: Int,
    @ColumnInfo(name = "reference_id") val referenceId: String = "",
    @ColumnInfo(name = "reference_type") val referenceType: String = "",
    @ColumnInfo(name = "courier_id") val courierId: Int? = null,
    @ColumnInfo(name = "notes") val notes: String = "",
    @ColumnInfo(name = "created_at") val createdAt: Long = System.currentTimeMillis()
) {
    @Serializable
    enum class MovementType {
        IN, OUT, TRANSFER, ADJUSTMENT, MISSION_ASSIGN, MISSION_RETURN
    }
}
