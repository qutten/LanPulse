package com.lanpulse.app

import android.content.Context
import android.net.wifi.WifiManager
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {

    private var multicastLock: WifiManager.MulticastLock? = null

    // 获取 MulticastLock：Android WiFi 默认过滤组播/广播包，
    // 不加锁则收不到自动发现广播（255.255.255.255）。
    override fun onStart() {
        super.onStart()
        try {
            val wifi = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
            multicastLock = wifi.createMulticastLock("lanpulse_discovery").apply {
                setReferenceCounted(false)
                acquire()
            }
        } catch (e: Exception) {
            // 获取失败不影响手动输入 IP 连接
        }
    }

    override fun onStop() {
        try {
            multicastLock?.let { if (it.isHeld) it.release() }
        } catch (e: Exception) {
        }
        multicastLock = null
        super.onStop()
    }
}
