package com.tammtool.marketerapp.data.local

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.Query
import com.tammtool.marketerapp.data.model.AuditLog
import kotlinx.coroutines.flow.Flow

@Dao
interface AuditLogDao {
    @Insert(onConflict = androidx.room.OnConflictStrategy.REPLACE)
    suspend fun insert(log: AuditLog): Long

    @Query("SELECT * FROM audit_logs ORDER BY changed_at DESC LIMIT :limit")
    fun getRecent(limit: Int): Flow<List<AuditLog>>
}
