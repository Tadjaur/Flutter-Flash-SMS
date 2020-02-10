package com.tadjaur.flash_sms

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.*
import android.widget.Toast
import com.tadjaur.flash_sms.Utils.Companion.log
import io.flutter.app.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import java.lang.Exception
import java.util.*
import kotlin.system.exitProcess


class MainActivity : FlutterActivity() {

    private var trycount: Int = 0
    private val channel = "com.tadjaur.flash_sms/sms"
    lateinit var methodChannel: MethodChannel
    private val postAction: ArrayList<Runnable> = ArrayList()
    private var allLoaded: Boolean = false
    private val permissions = arrayOf(
            PermissionsUtils.S_SMS,
            PermissionsUtils.R_SMS,
            PermissionsUtils.Rv_SMS,
            PermissionsUtils.CALL_PHONE,
            PermissionsUtils.R_CONTACTS,
            PermissionsUtils.W_CONTACTS,
            PermissionsUtils.VIB,
            PermissionsUtils.R_P_State)

    override fun onCreate(savedInstanceState: Bundle?) {
        mainActivity = this@MainActivity
        super.onCreate(savedInstanceState)
        GeneratedPluginRegistrant.registerWith(this)
        methodChannel = MethodChannel(flutterView, channel)
        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                (Methods.FP) -> {
                    val rn = Runnable {
                        checkFirstStart(result)
                        FetchSms().execute()
                        (application as FlashApplication).smsBroadcastReceiver.setListener(object : SmsBroadcastReceiver.Listener {
                            override fun onTextReceived(sender: String, body: String) {
                                val value = HashMap<String, String>()
                                value["msg"] = body
                                value["phone"] = sender
                                val t = SmsUtils.getContactByPhoneNumber(applicationContext, sender)
                                value["name"] = t.first
                                value["thumb"] = t.second
                                value["photo"] = t.third
                                runOnUiThread {
                                    try {
                                        methodChannel.invokeMethod(Methods.KSmsI, value)
                                    } catch (e: Exception) {
                                        log(e.message ?: "", tag)
                                    }
                                }
//                                Toast.makeText(applicationContext, "from:$sender\nbody:$body", Toast.LENGTH_LONG).show()
                            }
                        })
                    }
                    if (allLoaded) {
                        rn.run()
                    } else {
                        postAction.add(rn)
                    }

//                    methodChannel.invokeMethod(methods.KList, tmpList)
                }
                (Methods.SSms) -> {
                    val rn = Runnable {
                        try {
                            val arg = call.arguments as HashMap<*, *>
                            val num:String = arg["num"] as String
                            val msg:String = arg["msg"] as String
                            val id = "$num/${Random().nextLong()}"
                            SmsReceivers.sentAction[id] = object : SmsReceivers.VoidCallback {
                                override fun onBroadcastReceived(action: String, isSent: Boolean) {
                                    val curs = contentResolver.query( Uri.parse("content://sms"), null, "address=\"$num\"", null, "date desc limit 1")
                                    curs.run {
                                        if (this == null) return@run
                                        moveToFirst()
                                        val names = this.columnNames
                                        for (i in 0 until this.count) {
                                            val aux = SmsUtils.hashSmsCursorLine(this, names)
                                            result.success(aux)
                                            moveToNext()
                                        }
                                    }
                                    curs?.close()
                                }

                                override fun onBroadcastDelivered(action: String, isSent: Boolean) {
//                                    val curs = contentResolver.query( Uri.parse("content://sms"), null, "address=$num", null, "date desc limit 1")
//                                    curs.run {
//                                        if (this == null) return@run
//                                        moveToFirst()
//                                        val names = this.columnNames
//                                        for (i in 0 until this.count) {
//                                            val aux = SmsUtils.hashSmsCursorLine(this, names)
//                                            log(aux, "deliver")
//                                            moveToNext()
//                                        }
//                                    }
//                                    curs?.close()
                                }
                            }
                            Utils.sendSMS(applicationContext, msg, num, sentIntentId = id, deliveredIntentId = id)

                        } catch (e: Error) {
                            result.error("TYPE ERROR", "error when parsing param", e.message)
                        }
                    }
                    if (allLoaded) {
                        rn.run()
                    } else {
                        postAction.add(rn)
                    }
                }
                (Methods.RSms) -> {
                    val rn = Runnable {
                        result.success(null)
                    }
                    if (allLoaded) {
                        rn.run()
                    } else {
                        postAction.add(rn)
                    }
                }
                (Methods.Dial) -> {
                    val v = getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        v.vibrate(VibrationEffect.createOneShot(100, VibrationEffect.DEFAULT_AMPLITUDE))
                    } else {
                        v.vibrate(100)
                    }
                    val dial = "tel:${call.arguments}"
                    startActivity(Intent(Intent.ACTION_CALL, Uri.parse(dial)))
                }
                (Methods.KChatList) -> {
                    val rn = Runnable {
                        try {
                            val arg = call.arguments as HashMap<*, *>?
                            log(arg ?: 0)
                            FetchSms().execute("thread_id=${(arg!!["thread_id"] as String).toInt()}", Methods.KChatList)
                        } catch (e: Error) {
                            result.error(null, null, e.message)
                        }
                    }
                    if (allLoaded) {
                        rn.run()
                    } else {
                        postAction.add(rn)
                    }
                }
                else -> result.notImplemented()
            }
        }
        if (PermissionsUtils.checkAll(applicationContext, permissions, true, this@MainActivity)) {
            doneForAll()
        }


    }

    private fun checkFirstStart(result: MethodChannel.Result) {
        if (!(PreferenceUtils.get(Methods.FP, applicationContext, true).toString().toBoolean())) {
            result.success(false)
        } else {
            result.success(true)
            PreferenceUtils.set(Methods.FP, false, applicationContext)
        }
    }

    override fun onRequestPermissionsResult(requestCode: Int,
                                            permissions: Array<String>, grantResults: IntArray) {
        PermissionsUtils.onResult(
                requestCode = requestCode,
                permissions = permissions,
                grantResults = grantResults,
                cancelRunnable = Runnable {
                    trycount = 1
                    PermissionsUtils.requestPermission(this@MainActivity, permissions, PermissionsUtils.code)
                },
                deniedRunnable = Runnable {
                    if (trycount != 1) {
                        trycount = 1
                        PermissionsUtils.requestPermission(this@MainActivity, permissions, PermissionsUtils.code)
                    } else {
                        finish()
                        exitProcess(0)
                    }
                },
                runnable = Runnable { doneForAll() })
    }

    private fun doneForAll() {
        postAction.forEach { r -> r.run() }
        postAction.clear()
        allLoaded = true
    }

    companion object {
        private const val tag = "TAD::MainActivity"
        lateinit var mainActivity: MainActivity
        private class FetchSms : AsyncTask<String, Void, String>() {
            override fun doInBackground(vararg args: String): String {
                val select = if(args.isNotEmpty()) args[0] else "address IS NOT NULL) GROUP BY (thread_id"
                val method = if(args.size > 1) args[1] else Methods.KCOvList
                try {
                    val uriAll = Uri.parse("content://sms")
                    val curs = mainActivity.contentResolver.query(uriAll, null, select, null, "date desc") // 2nd null = "address IS NOT NULL) GROUP BY (address"
                    curs.run {
                        if (this == null) return@run
                        moveToFirst()
                        val names = this.columnNames
                        for (i in 0 until this.count) {
                            val aux = SmsUtils.hashSmsCursorLine(this, names)
                            mainActivity.runOnUiThread {
                                mainActivity.methodChannel.invokeMethod(method, aux)
                            }
                            moveToNext()
                        }
                    }
                    curs?.close()

                } catch (e: IllegalArgumentException) {
                    e.printStackTrace()
                }
//                try {
//                    SmsUtils.createCachedFile(mainActivity, "flashSms", mainActivity.smsList)
//                } catch (e: Exception) {
//                }

                //            Updating cache data

                return ""
            }

            override fun onPostExecute(xml: String) {
                log(xml)
            }
        }

    }


}

class Methods {
    companion object {
        const val FP = "firstOpen"
        const val SSms = "sendSms"
        const val RSms = "RetrieveAllSms"
        const val Dial = "newCall"
        const val KSmsI = "KotlinSmsIncoming"
        const val KCOvList = "KotlinChatOverviewList"
        const val KChatList = "KotlinChatList"
    }
}