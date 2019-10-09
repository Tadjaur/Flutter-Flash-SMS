package com.tadjaur.flash_sms

import android.content.IntentFilter
import android.provider.Telephony
import io.flutter.app.FlutterApplication

class FlashApplication: FlutterApplication() {
    lateinit var smsBroadcastReceiver: SmsBroadcastReceiver
    override fun onCreate() {
        smsBroadcastReceiver = SmsBroadcastReceiver()
        registerReceiver(smsBroadcastReceiver, IntentFilter(Telephony.Sms.Intents.SMS_RECEIVED_ACTION))
        super.onCreate()
    }

    override fun onTerminate() {
        unregisterReceiver(smsBroadcastReceiver)
        super.onTerminate()
    }

    companion object{
        const val tag = "Taur::FlashApplication"
    }
}