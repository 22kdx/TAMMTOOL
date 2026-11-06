package com.tammtool.ordersapp.data.local

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import androidx.room.migration.Migration
import androidx.room.Specification
import com.tammtool.ordersapp.data.model.*
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.launch

@Database(
    entities = [
        User::class, Order::class, Product::class, InventoryMovement::class,
        Mission::class, Commission::class, FinancialTransaction::class,
        AuditLog::class, Notification::class, Governorate::class, Branch::class
    ],
    version = 1,
    exportSchema = true
)
abstract class AppDatabase : RoomDatabase() {
    abstract fun userDao(): UserDao
    abstract fun orderDao(): OrderDao
    abstract fun productDao(): ProductDao
    abstract fun inventoryDao(): InventoryDao
    abstract fun missionDao(): MissionDao
    abstract fun commissionDao(): CommissionDao
    abstract fun financialTransactionDao(): FinancialTransactionDao
    abstract fun auditLogDao(): AuditLogDao
    abstract fun notificationDao(): NotificationDao
    abstract fun governorateDao(): GovernorateDao

    companion object {
        @Volatile
        private var INSTANCE: AppDatabase? = null

        fun getDatabase(context: Context): AppDatabase {
            return INSTANCE ?: synchronized(this) {
                Room.databaseBuilder(
                    context.applicationContext,
                    AppDatabase::class.java,
                    "orders_delivery_db"
                )
                    .fallbackToDestructiveMigration()
                    .build()
                    .also { INSTANCE = it }
            }
        }
    }
}
