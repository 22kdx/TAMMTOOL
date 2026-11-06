package com.tammtool.ordersapp.ui.viewmodel

import androidx.lifecycle.*
import com.tammtool.ordersapp.data.repository.UserRepository
import com.tammtool.ordersapp.data.model.User
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject

@HiltViewModel
class AuthViewModel @Inject constructor(
    private val userRepository: UserRepository
) : BaseViewModel() {

    private val _user = MutableLiveData<User?>(null)
    val user: LiveData<User?> = _user

    private val _error = MutableLiveData<String?>(null)
    val error: LiveData<String?> = _error

    private val _loading = MutableLiveData(false)
    val loading: LiveData<Boolean> = _loading

    fun login(phone: String, password: String) {
        _loading.value = true
        _error.value = null
        launchBlock {
            val existingUser = userRepository.getByPhone(phone)
            if (existingUser != null && existingUser.isActive) {
                _user.value = existingUser
            } else {
                _error.value = "بيانات الدخول غير صحيحة أو الحساب غير نشط"
            }
            _loading.value = false
        }
    }

    fun register(user: User) {
        _loading.value = true
        _error.value = null
        launchBlock {
            val existing = userRepository.getByPhone(user.phone)
            if (existing != null) {
                _error.value = "رقم الهاتف مسجل مسبقاً"
            } else {
                val id = userRepository.insert(user)
                _user.value = user.copy(id = id.toInt())
            }
            _loading.value = false
        }
    }

    fun logout() {
        _user.value = null
    }
}
