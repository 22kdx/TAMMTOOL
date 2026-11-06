package com.tammtool.ordersapp.ui.viewmodel

import kotlinx.coroutines.flow.first

import androidx.lifecycle.*
import com.tammtool.ordersapp.data.repository.CommissionRepository
import com.tammtool.ordersapp.data.model.Commission
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject

@HiltViewModel
class CommissionViewModel @Inject constructor(
    private val commissionRepository: CommissionRepository
) : BaseViewModel() {

    private val _commissions = MutableLiveData<List<Commission>>(emptyList())
    val commissions: LiveData<List<Commission>> = _commissions

    fun loadDueCommissionsForUser(userId: Int) {
        launchBlock {
            _commissions.value = commissionRepository.getDueByUserFlow(userId).first()
        }
    }

    fun loadCommissionsForUser(userId: Int) {
        launchBlock {
            _commissions.value = commissionRepository.getByUserFlow(userId).first()
        }
    }

    fun createCommission(commission: Commission) {
        launchBlock {
            try {
                commissionRepository.insert(commission)
                loadDueCommissionsForUser(commission.userId)
            } catch (e: Exception) {
                // Error handling
            }
        }
    }
}
