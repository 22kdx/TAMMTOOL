package com.tammtool.marketerapp.ui.viewmodel

import androidx.lifecycle.*
import com.tammtool.marketerapp.data.repository.MarketerUserRepository
import com.tammtool.marketerapp.data.model.MarketerUser
import com.tammtool.marketerapp.util.PasswordHasher
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

    private val _noAccounts = MutableLiveData(false)
    /** لا يوجد أي مستخدم في الجهاز ⇒ الشاشة تعرض «إنشاء أول حساب» بدل دخول مستحيل. */
    val noAccounts: LiveData<Boolean> = _noAccounts

    fun refreshFirstRunState() {
        launchBlock { _noAccounts.value = userRepository.count() == 0 }
    }

    fun login(phone: String, password: String) {
        _loading.value = true
        _error.value = null
        launchBlock {
            val existingUser = userRepository.getByPhone(phone)
            // نفس الرسالة في الحالتين: لا نسرّب أي رقم هاتف مسجّل
            val credentialsOk = existingUser != null &&
                existingUser.isActive &&
                PasswordHasher.verify(password, existingUser.passwordHash)
            if (existingUser != null && credentialsOk && PasswordHasher.needsRehash(existingUser.passwordHash)) {
                userRepository.update(existingUser.copy(passwordHash = PasswordHasher.hash(password)))
            }
            if (credentialsOk && existingUser != null) {
                _user.value = existingUser
            } else {
                _error.value = "بيانات الدخول غير صحيحة أو الحساب غير نشط"
            }
            _loading.value = false
        }
    }

    fun register(fullName: String, phone: String, password: String) {
        _loading.value = true
        _error.value = null
        launchBlock {
            when {
                fullName.isBlank() -> _error.value = "اكتب الاسم الكامل"
                phone.isBlank() -> _error.value = "اكتب رقم الهاتف"
                password.length < PasswordHasher.MIN_PASSWORD_LENGTH ->
                    _error.value = "كلمة المرور يجب ألا تقل عن ${PasswordHasher.MIN_PASSWORD_LENGTH} حرفاً"
                userRepository.getByPhone(phone) != null -> _error.value = "رقم الهاتف مسجّل مسبقاً"
                else -> {
                    val id = userRepository.insert(
                        MarketerUser(
                            fullName = fullName.trim(),
                            phone = phone.trim(),
                            passwordHash = PasswordHasher.hash(password)
                        )
                    )
                    _user.value = userRepository.getById(id.toInt())
                }
            }
            _loading.value = false
        }
    }

    fun logout() {
        _user.value = null
    }
}
