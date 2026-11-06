package com.tammtool.ordersapp.data.model

import androidx.room.Entity
import androidx.room.PrimaryKey
import androidx.room.ColumnInfo
import androidx.room.Index
import androidx.room.ForeignKey
import kotlinx.serialization.Serializable

@Serializable
@Entity(
    tableName = "users",
    indices = [Index(value = ["phone"], unique = true)],
    foreignKeys = [
        ForeignKey(
            entity = Governorate::class,
            parentColumns = ["id"],
            childColumns = ["governorate_id"],
            onDelete = ForeignKey.SET_NULL
        )
    ]
)
data class User(
    @PrimaryKey(autoGenerate = true)
    @ColumnInfo(name = "id") val id: Int = 0,
    @ColumnInfo(name = "full_name") val fullName: String,
    @ColumnInfo(name = "phone") val phone: String,
    @ColumnInfo(name = "password_hash") val passwordHash: String = "",
    @ColumnInfo(name = "role") val role: UserRole,
    @ColumnInfo(name = "governorate_id") val governorateId: Int? = null,
    @ColumnInfo(name = "branch_id") val branchId: Int? = null,
    @ColumnInfo(name = "commission_rate") val commissionRate: Double = 0.0,
    @ColumnInfo(name = "debt_limit") val debtLimit: Double = 0.0,
    @ColumnInfo(name = "is_active") val isActive: Boolean = true,
    @ColumnInfo(name = "wallet_balance") val walletBalance: Double = 0.0,
    @ColumnInfo(name = "created_at") val createdAt: Long = System.currentTimeMillis()
) {
    @Serializable
    enum class UserRole {
        SYSTEM_MANAGER, ADMINISTRATION, ORDERS_MANAGER, MARKETER, GOVERNORATE_COURIER, DELIVERY_COURIER, CUSTOMER
    }
}
