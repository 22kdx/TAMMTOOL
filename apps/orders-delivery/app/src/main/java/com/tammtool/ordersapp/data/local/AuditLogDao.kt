package com.tammtool.ordersapp.data.local

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.Query
import com.tammtool.ordersapp.data.model.AuditLog
import kotlinx.coroutines.flow.Flow

@Dao
interface AuditLogDao {
    @Insert(onConflict = androidx.room.OnConflictStrategy.REPLACE)
    suspend fun insert(log: AuditLog): Long

    @Query("SELECT * FROM audit_logs ORDER BY changed_at DESC LIMIT :limit")
    fun getRecent(limit: Int): Flow<List<AuditLog>>

    @Query("SELECT * FROM audit_logs WHERE entity_type = :entityType AND entity_id = :entityId ORDER BY changed_at DESC")
    fun getByEntity(entityType: String, entityId: Int): Flow<List<AuditLog>>
}
