package com.tammtool.ordersapp.ui.viewmodel

import kotlinx.coroutines.flow.first

import androidx.lifecycle.*
import com.tammtool.ordersapp.data.repository.FinancialRepository
import com.tammtool.ordersapp.data.model.FinancialTransaction
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject

@HiltViewModel
class FinancialViewModel @Inject constructor(
    private val financialRepository: FinancialRepository
) : BaseViewModel() {

    private val _transactions = MutableLiveData<List<FinancialTransaction>>(emptyList())
    val transactions: LiveData<List<FinancialTransaction>> = _transactions

    private val _pending = MutableLiveData<List<FinancialTransaction>>(emptyList())
    val pendingTransactions: LiveData<List<FinancialTransaction>> = _pending

    fun loadTransactionsForUser(userId: Int) {
        launchBlock {
            _transactions.value = financialRepository.getByUserFlow(userId).first()
        }
    }

    fun loadPendingTransactions() {
        launchBlock {
            _pending.value = financialRepository.getAllPendingFlow().first()
        }
    }

    fun createTransaction(transaction: FinancialTransaction) {
        launchBlock {
            try {
                financialRepository.insert(transaction)
                loadPendingTransactions()
            } catch (e: Exception) {
                // Error handling
            }
        }
    }

    fun approveTransaction(id: Int, approvedBy: Int?) {
        launchBlock {
            financialRepository.approve(id, approvedBy, System.currentTimeMillis())
            loadPendingTransactions()
        }
    }
}
