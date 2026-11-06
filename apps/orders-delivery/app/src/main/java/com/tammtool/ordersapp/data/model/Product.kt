package com.tammtool.ordersapp.data.model

import androidx.room.Entity
import androidx.room.PrimaryKey
import androidx.room.ColumnInfo
import kotlinx.serialization.Serializable

@Serializable
@Entity(tableName = "products")
data class Product(
    @PrimaryKey(autoGenerate = true)
    @ColumnInfo(name = "id") val id: Int = 0,
    @ColumnInfo(name = "name") val name: String,
    @ColumnInfo(name = "image_url") val imageUrl: String = "",
    @ColumnInfo(name = "unit") val unit: String = "قطعة",
    @ColumnInfo(name = "base_price") val basePrice: Double = 0.0,
    @ColumnInfo(name = "is_gift") val isGift: Boolean = false,
    @ColumnInfo(name = "is_active") val isActive: Boolean = true,
    @ColumnInfo(name = "min_stock_alert") val minStockAlert: Int = 0,
    @ColumnInfo(name = "cost") val cost: Double = 0.0,
    @ColumnInfo(name = "created_at") val createdAt: Long = System.currentTimeMillis()
)
