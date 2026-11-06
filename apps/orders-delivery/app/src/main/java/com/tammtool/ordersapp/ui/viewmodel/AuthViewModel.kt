package com.tammtool.ordersapp.ui.viewmodel

import androidx.lifecycle.*
import com.tammtool.ordersapp.data.repository.UserRepository
import com.tammtool.ordersapp.data.model.User
import com.tammtool.ordersapp.util.PasswordHasher
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

    private val _noAccounts = MutableLiveData(false)
    /** قاعدة المستخدمين فارغة ⇒ شاشة الدخول تعرض إنشاء أول حساب (وإلا كان الدخول مستحيلاً). */
    val noAccounts: LiveData<Boolean> = _noAccounts

    fun refreshFirstRunState() {
        launchBlock { _noAccounts.value = userRepository.count() == 0 }
    }

    fun login(phone: String, password: String) {
        _loading.value = true
        _error.value = null
        launchBlock {
            val existingUser = userRepository.getByPhone(phone)
            // رسالة واحدة للحالتين: لا تسريب لأي رقم هاتف مسجّل
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

    /** إنشاء حساب برقم هاتف + كلمة مرور (تُجزَّأ هنا) + دور. */
    fun register(fullName: String, phone: String, password: String, role: User.UserRole) {
        _loading.value = true
        _error.value = null
        launchBlock {
            when {
                fullName.isBlank() -> _error.value = "اكتب الاسم الكامل"
                phone.isBlank() -> _error.value = "اكتب رقم الهاتف"
                password.length < PasswordHasher.MIN_PASSWORD_LENGTH ->
                    _error.value = "كلمة المرور يجب ألا تقل عن ${PasswordHasher.MIN_PASSWORD_LENGTH} حرفاً"
                userRepository.getByPhone(phone) != null -> _error.value = "رقم الهاتف مسجل مسبقاً"
                else -> {
                    val id = userRepository.insert(
                        User(
                            fullName = fullName.trim(),
                            phone = phone.trim(),
                            passwordHash = PasswordHasher.hash(password),
                            role = role
                        )
                    )
                    _user.value = userRepository.getById(id.toInt())
                }
            }
            _loading.value = false
        }
    }

    /** النسخة القديمة تُقبل لكن تُجزَّأ كلمة المرور فيها إن وصلت نصاً صريحاً. */
    fun register(user: User) {
        _loading.value = true
        _error.value = null
        launchBlock {
            val existing = userRepository.getByPhone(user.phone)
            if (existing != null) {
                _error.value = "رقم الهاتف مسجل مسبقاً"
            } else {
                val secured = if (PasswordHasher.isStoredHash(user.passwordHash)) user
                              else user.copy(passwordHash = PasswordHasher.hash(user.passwordHash))
                val id = userRepository.insert(secured)
                _user.value = userRepository.getById(id.toInt()) ?: secured.copy(id = id.toInt())
            }
            _loading.value = false
        }
    }

    fun logout() {
        _user.value = null
    }
}
