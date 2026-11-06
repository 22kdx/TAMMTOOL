package com.tammtool.ordersapp.di

import android.content.Context
import com.tammtool.ordersapp.data.local.AppDatabase
import com.tammtool.ordersapp.data.local.*
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
    fun provideUserDao(database: AppDatabase): UserDao = database.userDao()
    @Provides
    @Singleton
    fun provideOrderDao(database: AppDatabase): OrderDao = database.orderDao()
    @Provides
    @Singleton
    fun provideProductDao(database: AppDatabase): ProductDao = database.productDao()
    @Provides
    @Singleton
    fun provideInventoryDao(database: AppDatabase): InventoryDao = database.inventoryDao()
    @Provides
    @Singleton
    fun provideMissionDao(database: AppDatabase): MissionDao = database.missionDao()
    @Provides
    @Singleton
    fun provideCommissionDao(database: AppDatabase): CommissionDao = database.commissionDao()
    @Provides
    @Singleton
    fun provideFinancialDao(database: AppDatabase): FinancialTransactionDao = database.financialTransactionDao()
    @Provides
    @Singleton
    fun provideAuditDao(database: AppDatabase): AuditLogDao = database.auditLogDao()
    @Provides
    @Singleton
    fun provideNotificationDao(database: AppDatabase): NotificationDao = database.notificationDao()
    @Provides
    @Singleton
    fun provideGovernorateDao(database: AppDatabase): GovernorateDao = database.governorateDao()
}
