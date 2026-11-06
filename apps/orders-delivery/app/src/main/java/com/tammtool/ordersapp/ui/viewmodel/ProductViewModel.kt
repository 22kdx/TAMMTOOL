package com.tammtool.ordersapp.ui.viewmodel

import kotlinx.coroutines.flow.first

import androidx.lifecycle.*
import com.tammtool.ordersapp.data.repository.ProductRepository
import com.tammtool.ordersapp.data.model.Product
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject

@HiltViewModel
class ProductViewModel @Inject constructor(
    private val productRepository: ProductRepository
) : BaseViewModel() {

    private val _products = MutableLiveData<List<Product>>(emptyList())
    val products: LiveData<List<Product>> = _products

    fun loadAllProducts() {
        launchBlock {
            _products.value = productRepository.getAllFlow().first()
        }
    }

    fun loadActiveProducts() {
        launchBlock {
            _products.value = productRepository.getAllActiveFlow().first()
        }
    }

    fun createProduct(product: Product) {
        launchBlock {
            try {
                productRepository.insert(product)
                loadAllProducts()
            } catch (e: Exception) {
                // Error handling
            }
        }
    }
}
