package com.tammtool.marketerapp.data.model

import androidx.room.Entity
import androidx.room.PrimaryKey
import androidx.room.ColumnInfo
import androidx.room.Index
import kotlinx.serialization.Serializable

@Serializable
@Entity(
    tableName = "audit_logs",
    indices = [Index(value = ["changedAt"]), Index(value = ["entityType"])]
)
data class AuditLog(
    @PrimaryKey(autoGenerate = true)
    @ColumnInfo(name = "id") val id: Int = 0,
    @ColumnInfo(name = "entity_type") val entityType: String,
    @ColumnInfo(name = "entity_id") val entityId: Int,
    @ColumnInfo(name = "field_name") val fieldName: String,
    @ColumnInfo(name = "old_value") val oldValue: String = "",
    @ColumnInfo(name = "new_value") val newValue: String = "",
    @ColumnInfo(name = "changed_by") val changedBy: Int,
    @ColumnInfo(name = "changed_by_name") val changedByName: String = "",
    @ColumnInfo(name = "changed_at") val changedAt: Long = System.currentTimeMillis()
)
