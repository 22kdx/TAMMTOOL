package com.tammtool.marketerapp.ui.viewmodel

import androidx.lifecycle.*
import com.tammtool.marketerapp.data.repository.MarketerCommissionRepository
import com.tammtool.marketerapp.data.model.MarketerCommission
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject

@HiltViewModel
class CommissionViewModel @Inject constructor(
    private val commissionRepository: MarketerCommissionRepository
) : BaseViewModel() {

    private val _commissions = MutableLiveData<List<MarketerCommission>>(emptyList())
    val commissions: LiveData<List<MarketerCommission>> = _commissions

    private val _totalDue = MutableLiveData(0.0)
    val totalDue: LiveData<Double> = _totalDue

    private val _totalPaid = MutableLiveData(0.0)
    val totalPaid: LiveData<Double> = _totalPaid

    fun loadAllCommissions() {
        launchBlock {
            _commissions.value = commissionRepository.getAllCommissionsFlow().first()
        }
    }

    fun loadCommissionsByStatus(status: MarketerCommission.CommissionStatus) {
        launchBlock {
            _commissions.value = commissionRepository.getByStatusFlow(status).first()
        }
    }

    fun loadTotals() {
        launchBlock {
            _totalDue.value = commissionRepository.getTotalByStatus(MarketerCommission.CommissionStatus.DUE)
            _totalPaid.value = commissionRepository.getTotalByStatus(MarketerCommission.CommissionStatus.PAID)
        }
    }
}
