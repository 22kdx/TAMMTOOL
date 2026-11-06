package com.tammtool.marketerapp.ui.viewmodel

import androidx.lifecycle.*
import com.tammtool.marketerapp.data.repository.MarketerUserRepository
import com.tammtool.marketerapp.data.model.MarketerUser
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject

@HiltViewModel
class AuthViewModel @Inject constructor(
    private val userRepository: MarketerUserRepository
) : BaseViewModel() {

    private val _user = MutableLiveData<MarketerUser?>(null)
    val user: LiveData<MarketerUser?> = _user

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

    fun logout() {
        _user.value = null
    }
}
