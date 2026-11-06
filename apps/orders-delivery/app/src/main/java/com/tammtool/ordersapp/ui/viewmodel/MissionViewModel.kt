package com.tammtool.ordersapp.ui.viewmodel

import kotlinx.coroutines.flow.first

import androidx.lifecycle.*
import com.tammtool.ordersapp.data.repository.MissionRepository
import com.tammtool.ordersapp.data.model.Mission
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject

@HiltViewModel
class MissionViewModel @Inject constructor(
    private val missionRepository: MissionRepository
) : BaseViewModel() {

    private val _missions = MutableLiveData<List<Mission>>(emptyList())
    val missions: LiveData<List<Mission>> = _missions

    fun loadActiveMissionsForCourier(courierId: Int) {
        launchBlock {
            _missions.value = missionRepository.getActiveByCourierFlow(courierId).first()
        }
    }

    fun loadMissionsForCourier(courierId: Int) {
        launchBlock {
            _missions.value = missionRepository.getByCourierFlow(courierId).first()
        }
    }

    fun createMission(mission: Mission) {
        launchBlock {
            try {
                missionRepository.insert(mission)
                loadActiveMissionsForCourier(mission.courierId)
            } catch (e: Exception) {
                // Error handling
            }
        }
    }
}
