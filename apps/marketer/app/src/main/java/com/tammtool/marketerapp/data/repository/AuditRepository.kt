package com.tammtool.marketerapp.data.repository

import com.tammtool.marketerapp.data.local.AuditLogDao
import com.tammtool.marketerapp.data.model.AuditLog
import kotlinx.coroutines.flow.Flow

class AuditRepository(private val auditDao: AuditLogDao) {
    suspend fun insert(log: AuditLog) = auditDao.insert(log)
    fun getRecentFlow(limit: Int): Flow<List<AuditLog>> = auditDao.getRecent(limit)
}
