package com.tammtool.marketerapp.data.local

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.Query
import androidx.room.Update
import com.tammtool.marketerapp.data.model.MarketerUser
import kotlinx.coroutines.flow.Flow

@Dao
interface MarketerUserDao {
    @Insert(onConflict = androidx.room.OnConflictStrategy.REPLACE)
    suspend fun insert(user: MarketerUser): Long

    @Update
    suspend fun update(user: MarketerUser)

    @Query("SELECT * FROM marketer_users WHERE phone = :phone")
    suspend fun getByPhone(phone: String): MarketerUser?

    @Query("SELECT * FROM marketer_users WHERE id = :id")
    suspend fun getById(id: Int): MarketerUser?

    @Query("SELECT * FROM marketer_users WHERE is_active = 1")
    fun getActiveUser(): Flow<MarketerUser?>

    // أول تشغيل: إن لم يوجد أي حساب يعرض LoginScreen نموذج إنشاء الحساب (بدون هذا يبقي login مستحيلاً)
    @Query("SELECT COUNT(*) FROM marketer_users")
    suspend fun count(): Int
}
