package com.tammtool.ordersapp.data.repository

import com.tammtool.ordersapp.data.local.AuditLogDao
import com.tammtool.ordersapp.data.model.AuditLog
import kotlinx.coroutines.flow.Flow

class AuditRepository(private val auditDao: AuditLogDao) {
    suspend fun insert(log: AuditLog) = auditDao.insert(log)
    fun getRecentFlow(limit: Int): Flow<List<AuditLog>> = auditDao.getRecent(limit)
    fun getByEntityFlow(entityType: String, entityId: Int): Flow<List<AuditLog>> = auditDao.getByEntity(entityType, entityId)
}
