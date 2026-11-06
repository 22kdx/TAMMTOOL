package com.tammtool.marketerapp.data.model

import androidx.room.Entity
import androidx.room.PrimaryKey
import androidx.room.ColumnInfo
import kotlinx.serialization.Serializable

@Serializable
@Entity(tableName = "marketer_users")
data class MarketerUser(
    @PrimaryKey(autoGenerate = true)
    @ColumnInfo(name = "id") val id: Int = 0,
    @ColumnInfo(name = "full_name") val fullName: String,
    @ColumnInfo(name = "phone") val phone: String,
    @ColumnInfo(name = "password_hash") val passwordHash: String = "",
    @ColumnInfo(name = "commission_rate") val commissionRate: Double = 0.0,
    @ColumnInfo(name = "wallet_balance") val walletBalance: Double = 0.0,
    @ColumnInfo(name = "debt_limit") val debtLimit: Double = 0.0,
    @ColumnInfo(name = "is_active") val isActive: Boolean = true,
    @ColumnInfo(name = "created_at") val createdAt: Long = System.currentTimeMillis()
)
