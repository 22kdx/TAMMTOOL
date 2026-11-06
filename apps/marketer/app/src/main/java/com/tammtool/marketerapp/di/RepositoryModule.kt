package com.tammtool.marketerapp.di

import com.tammtool.marketerapp.data.repository.*
import com.tammtool.marketerapp.data.local.*
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object RepositoryModule {

    @Provides
    @Singleton
    fun provideMarketerUserRepository(userDao: MarketerUserDao): MarketerUserRepository =
        MarketerUserRepository(userDao)
    @Provides
    @Singleton
    fun provideMarketerOrderRepository(orderDao: MarketerOrderDao): MarketerOrderRepository =
        MarketerOrderRepository(orderDao)
    @Provides
    @Singleton
    fun provideMarketerCommissionRepository(commissionDao: MarketerCommissionDao): MarketerCommissionRepository =
        MarketerCommissionRepository(commissionDao)
    @Provides
    @Singleton
    fun provideMarketerNotificationRepository(notificationDao: MarketerNotificationDao): MarketerNotificationRepository =
        MarketerNotificationRepository(notificationDao)
    @Provides
    @Singleton
    fun provideAuditRepository(auditDao: AuditLogDao): AuditRepository = AuditRepository(auditDao)
}
