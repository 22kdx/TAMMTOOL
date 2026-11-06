package com.tammtool.ordersapp.di

import com.tammtool.ordersapp.data.repository.*
import com.tammtool.ordersapp.data.local.*
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
    fun provideUserRepository(userDao: UserDao): UserRepository = UserRepository(userDao)
    @Provides
    @Singleton
    fun provideOrderRepository(orderDao: OrderDao): OrderRepository = OrderRepository(orderDao)
    @Provides
    @Singleton
    fun provideProductRepository(productDao: ProductDao): ProductRepository = ProductRepository(productDao)
    @Provides
    @Singleton
    fun provideInventoryRepository(inventoryDao: InventoryDao): InventoryRepository = InventoryRepository(inventoryDao)
    @Provides
    @Singleton
    fun provideMissionRepository(missionDao: MissionDao): MissionRepository = MissionRepository(missionDao)
    @Provides
    @Singleton
    fun provideCommissionRepository(commissionDao: CommissionDao): CommissionRepository = CommissionRepository(commissionDao)
    @Provides
    @Singleton
    fun provideFinancialRepository(financialDao: FinancialTransactionDao): FinancialRepository = FinancialRepository(financialDao)
    @Provides
    @Singleton
    fun provideAuditRepository(auditDao: AuditLogDao): AuditRepository = AuditRepository(auditDao)
    @Provides
    @Singleton
    fun provideNotificationRepository(notificationDao: NotificationDao): NotificationRepository = NotificationRepository(notificationDao)
    @Provides
    @Singleton
    fun provideGovernorateRepository(governorateDao: GovernorateDao): GovernorateRepository = GovernorateRepository(governorateDao)
}
