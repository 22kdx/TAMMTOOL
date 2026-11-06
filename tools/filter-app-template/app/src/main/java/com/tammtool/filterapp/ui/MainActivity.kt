package com.tammtool.filterapp.ui

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.core.content.ContextCompat
import androidx.lifecycle.viewmodel.compose.viewModel
import com.tammtool.filterapp.ui.screens.PermissionGate
import com.tammtool.filterapp.ui.screens.RootFilterScreen
import com.tammtool.filterapp.ui.theme.FilterTheme

class MainActivity : ComponentActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            val vm: FilterViewModel = viewModel(factory = FilterViewModelFactory(this))
            val granted = ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA) ==
                PackageManager.PERMISSION_GRANTED
            if (granted) {
                RootFilterScreen(vm)
            } else {
                PermissionGate(
                    onGrant = {
                        requestPermissions(arrayOf(Manifest.permission.CAMERA), REQUEST_CAMERA)
                    }
                )
            }
        }
    }

    private companion object {
        const val REQUEST_CAMERA = 41
    }
}
