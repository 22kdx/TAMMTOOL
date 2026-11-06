package com.tammtool.filterapp.ui

import android.content.Context
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import com.tammtool.filterapp.data.ShaderSourceRepository

/** مصنع بسيط بدل Hilt — لا يحتاج kapt ولا يضيف طبقة على مشروع بلا قاعدة بيانات. */
class FilterViewModelFactory(private val context: Context) : ViewModelProvider.Factory {
    @Suppress("UNCHECKED_CAST")
    override fun <T : ViewModel> create(modelClass: Class<T>): T {
        val repository = ShaderSourceRepository(context.applicationContext.assets)
        return FilterViewModel(repository) as T
    }
}
