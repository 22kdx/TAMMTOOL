package com.tammtool.ordersapp.ui.viewmodel

import androidx.lifecycle.*
import com.tammtool.ordersapp.data.repository.InventoryRepository
import com.tammtool.ordersapp.data.model.InventoryMovement
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject

@HiltViewModel
class InventoryViewModel @Inject constructor(
    private val inventoryRepository: InventoryRepository
) : BaseViewModel() {

    private val _movements = MutableLiveData<List<InventoryMovement>>(emptyList())
    val movements: LiveData<List<InventoryMovement>> = _movements

    fun loadMovements() {
        launchBlock {
            _movements.value = inventoryRepository.getAllFlow().first()
        }
    }

    fun recordMovement(movement: InventoryMovement) {
        launchBlock {
            try {
                inventoryRepository.insert(movement)
                loadMovements()
            } catch (e: Exception) {
                // Error handling
            }
        }
    }
}
