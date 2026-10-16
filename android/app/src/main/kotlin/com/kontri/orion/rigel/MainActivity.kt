package com.kontri.orion.rigel

import android.os.Build
import android.os.Bundle
import android.view.Display
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableHighRefreshRate()
    }

    override fun onResume() {
        super.onResume()
        enableHighRefreshRate()
    }

    private fun enableHighRefreshRate() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                @Suppress("DEPRECATION")
                val display: Display? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                    display
                } else {
                    windowManager.defaultDisplay
                }
                val modes = display?.supportedModes
                if (modes != null && modes.isNotEmpty()) {
                    var bestMode = modes[0]
                    var maxFps = bestMode.refreshRate
                    for (mode in modes) {
                        if (mode.refreshRate > maxFps) {
                            maxFps = mode.refreshRate
                            bestMode = mode
                        }
                    }
                    val params = window.attributes
                    params.preferredDisplayModeId = bestMode.modeId
                    params.preferredRefreshRate = maxFps
                    window.attributes = params
                }
            }
        } catch (_: Exception) {}
    }
}
