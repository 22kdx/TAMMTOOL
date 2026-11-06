package com.tammtool.marketerapp.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.launch

abstract class BaseViewModel : ViewModel() {
    protected fun launchBlock(block: suspend () -> Unit) {
        viewModelScope.launch { block() }
    }
}
