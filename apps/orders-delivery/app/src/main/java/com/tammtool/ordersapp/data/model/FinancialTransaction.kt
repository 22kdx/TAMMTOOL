package com.tammtool.ordersapp.data.model

import androidx.room.Entity
import androidx.room.PrimaryKey
import androidx.room.ColumnInfo
import androidx.room.Index
import androidx.room.ForeignKey
import kotlinx.serialization.Serializable

@Serializable
@Entity(
    tableName = "financial_transactions",
    indices = [Index(value = ["walletId"]), Index(value = ["status"]), Index(value = ["createdAt"])],
    foreignKeys = [
        ForeignKey(
            entity = User::class,
            parentColumns = ["id"],
            childColumns = ["walletId"],
            onDelete = ForeignKey.CASCADE
        )
    ]
)
data class FinancialTransaction(
    @PrimaryKey(autoGenerate = true)
    @ColumnInfo(name = "id") val id: Int = 0,
    @ColumnInfo(name = "wallet_id") val walletId: Int,
    @ColumnInfo(name = "user_id") val userId: Int,
    @ColumnInfo(name = "transaction_type") val transactionType: TransactionType,
    @ColumnInfo(name = "amount") val amount: Double,
    @ColumnInfo(name = "reference_type") val referenceType: String = "",
    @ColumnInfo(name = "reference_id") val referenceId: Int = 0,
    @ColumnInfo(name = "status") val status: TransactionStatus = TransactionStatus.PENDING,
    @ColumnInfo(name = "approved_by") val approvedBy: Int? = null,
    @ColumnInfo(name = "approved_at") val approvedAt: Long = 0,
    @ColumnInfo(name = "image_uri") val imageUri: String = "",
    @ColumnInfo(name = "notes") val notes: String = "",
    @ColumnInfo(name = "created_at") val createdAt: Long = System.currentTimeMillis()
) {
    @Serializable
    enum class TransactionType {
        CREDIT, DEBIT
    }

    @Serializable
    enum class TransactionStatus {
        PENDING, APPROVED, REJECTED
    }
}
