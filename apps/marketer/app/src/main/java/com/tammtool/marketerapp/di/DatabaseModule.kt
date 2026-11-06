package com.tammtool.marketerapp.di

import android.content.Context
import com.tammtool.marketerapp.data.local.AppDatabase
import com.tammtool.marketerapp.data.local.*
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object DatabaseModule {

    @Provides
    @Singleton
    fun provideDatabase(@ApplicationContext context: Context): AppDatabase {
        return AppDatabase.getDatabase(context)
    }

    @Provides
    @Singleton
    fun provideMarketerUserDao(database: AppDatabase): MarketerUserDao = database.marketerUserDao()
    @Provides
    @Singleton
    fun provideMarketerOrderDao(database: AppDatabase): MarketerOrderDao = database.marketerOrderDao()
    @Provides
    @Singleton
    fun provideMarketerCommissionDao(database: AppDatabase): MarketerCommissionDao = database.marketerCommissionDao()
    @Provides
    @Singleton
    fun provideMarketerNotificationDao(database: AppDatabase): MarketerNotificationDao = database.marketerNotificationDao()
    @Provides
    @Singleton
    fun provideAuditLogDao(database: AppDatabase): AuditLogDao = database.auditLogDao()
}
