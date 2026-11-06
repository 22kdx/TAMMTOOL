package com.tammtool.ordersapp.di

import android.app.Application
import com.tammtool.ordersapp.data.local.AppDatabase
import dagger.hilt.android.HiltAndroidApp

@HiltAndroidApp
class OrdersApp : Application() {
    val database: AppDatabase by lazy { AppDatabase.getDatabase(this) }
}
