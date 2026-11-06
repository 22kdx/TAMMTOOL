package com.tammtool.ordersapp.data.model

import androidx.room.Entity
import androidx.room.PrimaryKey
import androidx.room.ColumnInfo
import kotlinx.serialization.Serializable

@Serializable
@Entity(tableName = "branches")
data class Branch(
    @PrimaryKey(autoGenerate = true)
    @ColumnInfo(name = "id") val id: Int = 0,
    @ColumnInfo(name = "name") val name: String,
    @ColumnInfo(name = "balance") val balance: Double = 0.0,
    @ColumnInfo(name = "is_active") val isActive: Boolean = true
)
