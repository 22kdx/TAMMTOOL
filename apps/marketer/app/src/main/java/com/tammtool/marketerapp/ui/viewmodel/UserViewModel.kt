package com.tammtool.marketerapp.ui.viewmodel

import kotlinx.coroutines.flow.first

import androidx.lifecycle.*
import com.tammtool.marketerapp.data.repository.MarketerUserRepository
import com.tammtool.marketerapp.data.model.MarketerUser
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject

@HiltViewModel
class UserViewModel @Inject constructor(
    private val userRepository: MarketerUserRepository
) : BaseViewModel() {

    private val _user = MutableLiveData<MarketerUser?>(null)
    val user: LiveData<MarketerUser?> = _user

    fun loadActiveUser() {
        launchBlock {
            _user.value = userRepository.getActiveUserFlow().first()
        }
    }
}
