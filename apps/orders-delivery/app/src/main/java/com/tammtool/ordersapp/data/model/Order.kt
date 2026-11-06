package com.tammtool.ordersapp.data.model

import androidx.room.Entity
import androidx.room.PrimaryKey
import androidx.room.ColumnInfo
import androidx.room.Index
import androidx.room.ForeignKey
import kotlinx.serialization.Serializable

@Serializable
@Entity(
    tableName = "orders",
    indices = [
        Index(value = ["orderNumber"], unique = true),
        Index(value = ["status"]),
        Index(value = ["courierId"]),
        Index(value = ["marketerId"]),
        Index(value = ["customerPhone"]),
        Index(value = ["createdAt"])
    ],
    foreignKeys = [
        ForeignKey(
            entity = User::class,
            parentColumns = ["id"],
            childColumns = ["courierId"],
            onDelete = ForeignKey.SET_NULL
        ),
        ForeignKey(
            entity = User::class,
            parentColumns = ["id"],
            childColumns = ["marketerId"],
            onDelete = ForeignKey.SET_NULL
        )
    ]
)
data class Order(
    @PrimaryKey(autoGenerate = true)
    @ColumnInfo(name = "id") val id: Int = 0,
    @ColumnInfo(name = "order_number") val orderNumber: String,
    @ColumnInfo(name = "customer_name") val customerName: String,
    @ColumnInfo(name = "customer_phone") val customerPhone: String,
    @ColumnInfo(name = "governorate") val governorate: String,
    @ColumnInfo(name = "address") val address: String,
    @ColumnInfo(name = "website_link") val websiteLink: String = "",
    @ColumnInfo(name = "product") val product: String,
    @ColumnInfo(name = "quantity") val quantity: Int,
    @ColumnInfo(name = "gift") val gift: String = "",
    @ColumnInfo(name = "gift_quantity") val giftQuantity: Int = 0,
    @ColumnInfo(name = "agreed_price") val agreedPrice: Double,
    @ColumnInfo(name = "delivery_date_time") val deliveryDateTime: Long,
    @ColumnInfo(name = "status") val status: OrderStatus = OrderStatus.SUSPENDED,
    @ColumnInfo(name = "courier_id") val courierId: Int? = null,
    @ColumnInfo(name = "marketer_id") val marketerId: Int? = null,
    @ColumnInfo(name = "delivery_commission") val deliveryCommission: Double = 0.0,
    @ColumnInfo(name = "marketer_commission") val marketerCommission: Double = 0.0,
    @ColumnInfo(name = "amount_collected") val amountCollected: Double = 0.0,
    @ColumnInfo(name = "amount_collected_image") val amountCollectedImage: String = "",
    @ColumnInfo(name = "delivered_quantity") val deliveredQuantity: Int = 0,
    @ColumnInfo(name = "changed_by") val changedBy: Int? = null,
    @ColumnInfo(name = "change_reason") val changeReason: String = "",
    @ColumnInfo(name = "changed_at") val changedAt: Long = 0,
    @ColumnInfo(name = "created_at") val createdAt: Long = System.currentTimeMillis(),
    @ColumnInfo(name = "updated_at") val updatedAt: Long = System.currentTimeMillis()
) {
    @Serializable
    enum class OrderStatus {
        SUSPENDED, IN_COMMUNICATION, COURIER_APPROVED, AWAITING_PRICE_APPROVAL,
        AWAITING_QUANTITY_APPROVAL, POSTPONED, CANCELLED, DELIVERED, COMPLETED
    }
}
