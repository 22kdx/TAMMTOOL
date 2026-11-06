package com.tammtool.filterapp.ui

import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.tammtool.filterapp.data.ShaderSourceRepository
import com.tammtool.filterapp.domain.Filter
import com.tammtool.filterapp.domain.FilterRegistry
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

/**
 * ViewModel بلا Hilt وبلا LiveData.map: المشروع صغير، وأقل أدوات = أقل فرص فشل kapt
 * (سبب فشل CI 42274698250 كان خياراً في إعداد kapt، لا في الكود).
 */
class FilterViewModel(private val repository: ShaderSourceRepository) : ViewModel() {

    private val _filters = MutableLiveData(FilterRegistry.all)
    val filters: LiveData<List<Filter>> = _filters

    private val _selected = MutableLiveData(FilterRegistry.default)
    val selected: LiveData<Filter> = _selected

    private val _intensity = MutableLiveData(0.5f)
    val intensity: LiveData<Float> = _intensity

    private val _shaderSource = MutableLiveData<String?>(null)
    val shaderSource: LiveData<String?> = _shaderSource

    private val _error = MutableLiveData<String?>(null)
    val error: LiveData<String?> = _error

    fun select(filter: Filter) {
        _selected.value = filter
        _intensity.value = filter.clampIntensity(_intensity.value ?: 0.5f)
        loadShader(filter)
    }

    fun setIntensity(raw: Float) {
        _intensity.value = (_selected.value ?: FilterRegistry.default).clampIntensity(raw)
    }

    private fun loadShader(filter: Filter) {
        if (filter.id == "none") { _shaderSource.value = null; return }
        viewModelScope.launch {
            val text = withContext(Dispatchers.IO) { runCatching { repository.read(filter) }.getOrNull() }
            if (text.isNullOrBlank()) {
                _error.value = "ملف الشيدر مفقود: ${filter.assetPath}"
                _shaderSource.value = null
            } else {
                _error.value = null
                _shaderSource.value = text
            }
        }
    }
}
