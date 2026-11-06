package com.tammtool.ordersapp.ui.viewmodel

import androidx.lifecycle.*
import com.tammtool.ordersapp.data.repository.UserRepository
import com.tammtool.ordersapp.data.model.User
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject

@HiltViewModel
class UserViewModel @Inject constructor(
    private val userRepository: UserRepository
) : BaseViewModel() {

    private val _users = MutableLiveData<List<User>>(emptyList())
    val users: LiveData<List<User>> = _users

    private val _error = MutableLiveData<String?>(null)
    val error: LiveData<String?> = _error

    fun loadUsersByRole(role: User.UserRole) {
        launchBlock {
            _users.value = userRepository.getByRoleFlow(role).first()
        }
    }

    fun loadAllActiveUsers() {
        launchBlock {
            _users.value = userRepository.getAllActiveFlow().first()
        }
    }

    fun createUser(user: User) {
        _error.value = null
        launchBlock {
            try {
                userRepository.insert(user)
                loadAllActiveUsers()
            } catch (e: Exception) {
                _error.value = e.message
            }
        }
    }

    fun deactivateUser(id: Int) {
        launchBlock {
            userRepository.deactivate(id)
            loadAllActiveUsers()
        }
    }
}
