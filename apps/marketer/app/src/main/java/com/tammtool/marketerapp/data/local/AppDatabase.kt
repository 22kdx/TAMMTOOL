package com.tammtool.marketerapp.data.local

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import com.tammtool.marketerapp.data.model.*

@Database(
    entities = [
        MarketerUser::class, MarketerOrder::class, MarketerCommission::class,
        MarketerNotification::class, AuditLog::class
    ],
    version = 1,
    exportSchema = true
)
abstract class AppDatabase : RoomDatabase() {
    abstract fun marketerUserDao(): MarketerUserDao
    abstract fun marketerOrderDao(): MarketerOrderDao
    abstract fun marketerCommissionDao(): MarketerCommissionDao
    abstract fun marketerNotificationDao(): MarketerNotificationDao
    abstract fun auditLogDao(): AuditLogDao

    companion object {
        @Volatile
        private var INSTANCE: AppDatabase? = null

        fun getDatabase(context: Context): AppDatabase {
            return INSTANCE ?: synchronized(this) {
                Room.databaseBuilder(
                    context.applicationContext,
                    AppDatabase::class.java,
                    "marketer_app_db"
                )
                    .fallbackToDestructiveMigration()
                    .build()
                    .also { INSTANCE = it }
            }
        }
    }
}
