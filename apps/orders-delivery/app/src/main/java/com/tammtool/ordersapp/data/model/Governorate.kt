package com.tammtool.ordersapp.data.model

import androidx.room.Entity
import androidx.room.PrimaryKey
import androidx.room.ColumnInfo
import kotlinx.serialization.Serializable

@Serializable
@Entity(tableName = "governorates")
data class Governorate(
    @PrimaryKey(autoGenerate = true)
    @ColumnInfo(name = "id") val id: Int = 0,
    @ColumnInfo(name = "name") val name: String,
    @ColumnInfo(name = "delivery_price") val deliveryPrice: Double = 0.0,
    @ColumnInfo(name = "manager_id") val managerId: Int? = null,
    @ColumnInfo(name = "is_active") val isActive: Boolean = true
)
