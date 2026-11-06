@file:OptIn(androidx.compose.material3.ExperimentalMaterial3Api::class)

package com.tammtool.marketerapp.ui.screens

import androidx.compose.runtime.livedata.observeAsState
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.Alignment

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.tammtool.marketerapp.data.model.MarketerCommission
import com.tammtool.marketerapp.ui.theme.MarketerTheme
import com.tammtool.marketerapp.ui.viewmodel.CommissionViewModel
import androidx.hilt.navigation.compose.hiltViewModel

@Composable
fun MyCommissionsScreen(viewModel: CommissionViewModel = hiltViewModel()) {
    val commissions by viewModel.commissions.observeAsState(initial = emptyList())
    val totalDue by viewModel.totalDue.observeAsState(initial = 0.0)
    val totalPaid by viewModel.totalPaid.observeAsState(initial = 0.0)

    Column(modifier = Modifier.fillMaxSize()) {
        TopAppBar(
            title = { Text("عمولاتي") },
            colors = TopAppBarDefaults.mediumTopAppBarColors(
                containerColor = MaterialTheme.colorScheme.primaryContainer
            ),
            actions = {
                IconButton(onClick = { viewModel.loadTotals() }) {
                    Icon(Icons.Default.Refresh, contentDescription = "تحديث")
                }
            }
        )

        Column(
            modifier = Modifier.fillMaxWidth().padding(16.dp)
        ) {
            Card(
                modifier = Modifier.fillMaxWidth(),
                elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Text(text = "ملخص العمولات", style = MaterialTheme.typography.titleMedium)
                    Spacer(modifier = Modifier.height(12.dp))
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = androidx.compose.foundation.layout.Arrangement.SpaceBetween
                    ) {
                        Column {
                            Text(text = "المستحق", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                            Text(text = "${totalDue} ريال", style = MaterialTheme.typography.titleMedium.copy(color = MaterialTheme.colorScheme.error))
                        }
                        Column {
                            Text(text = "المدفوع", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                            Text(text = "${totalPaid} ريال", style = MaterialTheme.typography.titleMedium.copy(color = Color(0xFF4CAF50)))
                        }
                    }
                }
            }
            Spacer(modifier = Modifier.height(16.dp))

            Text(text = "سجل العمولات", style = MaterialTheme.typography.titleMedium, modifier = Modifier.padding(horizontal = 16.dp))
            Spacer(modifier = Modifier.height(8.dp))

            if (commissions.isEmpty()) {
                Text(text = "لا توجد عمولات حالياً", style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant, modifier = Modifier.padding(16.dp))
            } else {
                androidx.compose.foundation.lazy.LazyColumn(
                    modifier = Modifier.fillMaxSize().padding(8.dp)
                ) {
                    items(commissions) { commission ->
                        CommissionCard(commission = commission)
                    }
                }
            }
        }
    }
}

@Composable
private fun CommissionCard(commission: MarketerCommission) {
    Card(
        modifier = Modifier.fillMaxWidth().padding(8.dp),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Row(
            modifier = Modifier.padding(16.dp),
            verticalAlignment = androidx.compose.ui.Alignment.CenterVertically
        ) {
            Column {
                Text(text = "طلب #${commission.orderNumber}", style = MaterialTheme.typography.titleMedium)
                Text(text = "${commission.amount} ريال", style = MaterialTheme.typography.bodyMedium.copy(fontWeight = androidx.compose.ui.text.font.FontWeight.W500))
            }
            Spacer(modifier = Modifier.weight(1f))
            SuggestionChip(onClick = {}, 
                label = { Text(commission.status.name) },
                colors = SuggestionChipDefaults.suggestionChipColors(
                    containerColor = when (commission.status) {
                        MarketerCommission.CommissionStatus.DUE -> MaterialTheme.colorScheme.secondaryContainer
                        MarketerCommission.CommissionStatus.PAID -> Color(0xFF4CAF50).copy(alpha = 0.2f)
                        MarketerCommission.CommissionStatus.CANCELLED -> MaterialTheme.colorScheme.errorContainer
                    }
                )
            )
        }
    }
}
