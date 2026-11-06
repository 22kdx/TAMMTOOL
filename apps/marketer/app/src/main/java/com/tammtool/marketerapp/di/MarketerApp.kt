package com.tammtool.marketerapp.di

import android.app.Application
import com.tammtool.marketerapp.data.local.AppDatabase
import dagger.hilt.android.HiltAndroidApp

@HiltAndroidApp
class MarketerApp : Application() {
    val database: AppDatabase by lazy { AppDatabase.getDatabase(this) }
}
