package com.example.autoclicker

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.GestureDescription
import android.content.Intent
import android.graphics.Path
import android.graphics.PixelFormat
import android.os.Handler
import android.os.Looper
import android.view.Gravity
import android.view.WindowManager
import android.view.accessibility.AccessibilityEvent
import android.widget.Button

class ClickService : AccessibilityService() {
    companion object {
        var instance: ClickService? = null
    }

    private val handler = Handler(Looper.getMainLooper())
    var running = false
        private set
    private var x = 0f
    private var y = 0f
    private var interval = 1000L
    private var max = 0
    private var count = 0
    private var stopBtn: Button? = null

    override fun onServiceConnected() {
        instance = this
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {}
    override fun onInterrupt() {}

    override fun onUnbind(intent: Intent?): Boolean {
        stopClicking()
        instance = null
        return super.onUnbind(intent)
    }

    private val tick = object : Runnable {
        override fun run() {
            if (!running) return
            val path = Path().apply { moveTo(x, y) }
            val gesture = GestureDescription.Builder()
                .addStroke(GestureDescription.StrokeDescription(path, 0, 50))
                .build()
            dispatchGesture(gesture, null, null)
            count++
            if (max > 0 && count >= max) {
                stopClicking()
                return
            }
            handler.postDelayed(this, interval)
        }
    }

    fun startClicking(x: Float, y: Float, interval: Long, max: Int) {
        stopClicking()
        this.x = x
        this.y = y
        this.interval = if (interval < 20) 20 else interval
        this.max = max
        this.count = 0
        running = true
        showStopButton()
        handler.post(tick)
    }

    fun stopClicking() {
        running = false
        handler.removeCallbacks(tick)
        removeStopButton()
    }

    private fun showStopButton() {
        val wm = getSystemService(WINDOW_SERVICE) as WindowManager
        val btn = Button(this).apply {
            text = "STOP"
            setOnClickListener { stopClicking() }
        }
        val lp = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            PixelFormat.TRANSLUCENT
        )
        lp.gravity = Gravity.TOP or Gravity.END
        lp.y = 200
        wm.addView(btn, lp)
        stopBtn = btn
    }

    private fun removeStopButton() {
        stopBtn?.let {
            try {
                (getSystemService(WINDOW_SERVICE) as WindowManager).removeView(it)
            } catch (e: Exception) {
            }
        }
        stopBtn = null
    }
}
