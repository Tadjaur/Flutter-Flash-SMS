package com.tadjaur.flash_sms

import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.database.MergeCursor
import android.net.Uri
import android.os.*
import android.support.v4.app.ActivityCompat
import android.support.v4.content.ContextCompat
import android.util.Log
import android.widget.Toast
import io.flutter.app.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import java.util.*
import kotlin.collections.ArrayList
import kotlin.collections.HashMap
import kotlin.system.exitProcess


class MainActivity : FlutterActivity() {

    private var trycount: Int = 0;
    private val channel = "com.tadjaur.flash_sms/sms"
    lateinit var methodChannel: MethodChannel
    private lateinit var loadsmsTask: LoadSms
    lateinit var smsList: ArrayList<HashMap<String, String>>
    lateinit var tmpList: ArrayList<HashMap<String, String>>
    private val postAction: ArrayList<Runnable> = ArrayList()
    private var allLoaded: Boolean = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        GeneratedPluginRegistrant.registerWith(this)
        smsList = ArrayList()
        instance = this
        try {
            tmpList = SmsUtils.readCachedFile(applicationContext, "flashSms") as ArrayList<HashMap<String, String>>
        } catch (e: Exception) {
            tmpList = ArrayList()
            print("\n$tag:::")
            println(e.message)
            println()
        }
        methodChannel = MethodChannel(flutterView, channel)
        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                (methods.FP) -> {
                    val rn = Runnable {
                        checkFirstStart(result)
                        loadsmsTask = LoadSms(this@MainActivity)
                        loadsmsTask.execute()
                    }
                    if (allLoaded) {
                        rn.run()
                    } else {
                        postAction.add(rn)
                    }

//                    methodChannel.invokeMethod(methods.KList, tmpList)
                }
                (methods.SSms) -> {
                    val rn = Runnable {
                        sendNewMessage(call.arguments, result)
                    }
                    if (allLoaded) {
                        rn.run()
                    } else {
                        postAction.add(rn)
                    }
                }
                (methods.RSms) -> {
                    val rn = Runnable {
                        getAllMessages(result)
                    }
                    if (allLoaded) {
                        rn.run()
                    } else {
                        postAction.add(rn)
                    }
                }
                (methods.Dial) -> {
                    val v = getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
                    // Vibrate for 500 milliseconds
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        v.vibrate(VibrationEffect.createOneShot(50, VibrationEffect.DEFAULT_AMPLITUDE))
                    } else {
                        //deprecated in API 26
                        v.vibrate(50)
                    }
                    val dial = "tel:${call.arguments}"
                    startActivity(Intent(Intent.ACTION_CALL, Uri.parse(dial)))
                }
                (methods.KChatList) -> {
                    val rn = Runnable {
                        try {
                            val arg = call.arguments as HashMap<*, *>?
                            val loadchat = LoadChat((arg!!["thread_id"] as String).toInt(), arg["name"] as String)
                            loadchat.execute()
                            (application as FlashApplication).smsBroadcastReceiver.setListener(object : SmsBroadcastReceiver.Listener {
                                override fun onTextReceived(sender: String, body: String) {
                                    val value = HashMap<String, String>()
                                    value["msg"] = body
                                    value["adr"] = sender
                                    if (sender == arg["num"].toString()) {
                                        methodChannel.invokeMethod(methods.KSmsI, value)
                                    } else {
                                        Toast.makeText(applicationContext, "from:$sender\nbody:$body", Toast.LENGTH_LONG).show()
                                    }
                                }
                            })
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
        if (!isSmsPermissionGranted(android.Manifest.permission.RECEIVE_SMS) ||
                !isSmsPermissionGranted(android.Manifest.permission.READ_SMS) ||
                !isSmsPermissionGranted(android.Manifest.permission.SEND_SMS) ||
                !isSmsPermissionGranted(android.Manifest.permission.READ_PHONE_STATE) ||
                !isSmsPermissionGranted(android.Manifest.permission.READ_CONTACTS) ||
                !isSmsPermissionGranted(android.Manifest.permission.WRITE_CONTACTS) ||
                !isSmsPermissionGranted(android.Manifest.permission.VIBRATE) ||
                !isSmsPermissionGranted(android.Manifest.permission.CALL_PHONE)) {
            requestPermission()
        } else {
            doneForAll()
        }


    }

    private fun getAllMessages(result: MethodChannel.Result) {
        result.success(null)
    }

    private fun sendNewMessage(arguments: Any?, result: MethodChannel.Result) {
        try {
            val arg = arguments as HashMap<*, *>?
            val test = SmsUtils.sendSMS(arg!!["num"] as String, arg["msg"] as String)
            result.success(test);
        } catch (e: Error) {
            result.error("TYPE ERROR", "error when parsing param", e.message)
        }
    }


    private fun checkFirstStart(result: MethodChannel.Result) {
        val pref = applicationContext.getSharedPreferences(PREFS_FILE, Context.MODE_PRIVATE)
        if (!pref.getBoolean(methods.FP, true)) {
            result.success(false)
        } else {
            result.success(true)
            pref.edit().putBoolean(methods.FP, false).apply()
        }
    }

    private fun isSmsPermissionGranted(permission: String): Boolean {
        val v1 = ContextCompat.checkSelfPermission(applicationContext, permission)
        val v2 = PackageManager.PERMISSION_GRANTED
        return v1 == v2
    }

    private fun requestPermission() {
        if (ActivityCompat.shouldShowRequestPermissionRationale(this, android.Manifest.permission.RECEIVE_SMS) ||
                ActivityCompat.shouldShowRequestPermissionRationale(this, android.Manifest.permission.READ_SMS) ||
                ActivityCompat.shouldShowRequestPermissionRationale(this, android.Manifest.permission.SEND_SMS) ||
                ActivityCompat.shouldShowRequestPermissionRationale(this, android.Manifest.permission.READ_PHONE_STATE) ||
                ActivityCompat.shouldShowRequestPermissionRationale(this, android.Manifest.permission.READ_CONTACTS) ||
                ActivityCompat.shouldShowRequestPermissionRationale(this, android.Manifest.permission.WRITE_CONTACTS) ||
                ActivityCompat.shouldShowRequestPermissionRationale(this, android.Manifest.permission.VIBRATE) ||
                ActivityCompat.shouldShowRequestPermissionRationale(this, android.Manifest.permission.CALL_PHONE)) {
            // Non blocking code
        }
        ActivityCompat.requestPermissions(this, arrayOf(
                android.Manifest.permission.RECEIVE_SMS,
                android.Manifest.permission.READ_SMS,
                android.Manifest.permission.SEND_SMS,
                android.Manifest.permission.READ_PHONE_STATE,
                android.Manifest.permission.READ_CONTACTS,
                android.Manifest.permission.WRITE_CONTACTS,
                android.Manifest.permission.VIBRATE,
                android.Manifest.permission.CALL_PHONE), smsPermissionCode)
    }


    override fun onRequestPermissionsResult(requestCode: Int,
                                            permissions: Array<String>, grantResults: IntArray) {
        when (requestCode) {
            smsPermissionCode -> {
                // If request is cancelled, the result arrays are empty.
                if (grantResults.isNotEmpty()) {
                    var idx = 0
                    while (idx < grantResults.size) {
                        if (grantResults[0] != PackageManager.PERMISSION_GRANTED) {
                            if (trycount != 1) {
                                trycount = 1
                                requestPermission()
                            } else {
                                finish()
                                exitProcess(0)
                            }
                            return
                        }
                        idx++
                    }
                    doneForAll()
                }
                return
            }
        }
    }

    private fun doneForAll() {
        postAction.forEach { r -> r.run() }
        postAction.clear()
        allLoaded = true
    }

    companion object {
        private const val tag = "TAD::MainActivity"
        private const val smsPermissionCode = 9
        lateinit var instance: MainActivity
        private const val PREFS_FILE = "com.tadjaur.flash_sms.pref_file"
    }


    internal inner class LoadSms(private val caller: MainActivity) : AsyncTask<String, Void, String>() {

        override fun onPreExecute() {
            super.onPreExecute()
            smsList.clear()
        }

        override fun doInBackground(vararg args: String): String {
            val xml = ""

            try {
                val uriInbox = Uri.parse("content://sms/inbox")
                val inbox = contentResolver.query(uriInbox, null, "address IS NOT NULL) GROUP BY (thread_id", null, "date desc") // 2nd null = "address IS NOT NULL) GROUP BY (address"
                val uriSent = Uri.parse("content://sms/sent")
                val sent = contentResolver.query(uriSent, null, "address IS NOT NULL) GROUP BY (thread_id", null, "date desc") // 2nd null = "address IS NOT NULL) GROUP BY (address"
                val c = MergeCursor(arrayOf(inbox, sent)) // Attaching inbox and sent sms


                if (c.moveToFirst()) {
//                    //todo: remove these lines
                    println()
                    println("# column list")
                    val cn = c.columnNames
                    for (i in 0 until c.columnCount) {
                        println(cn[i])
                    }
                    println()
                    println("# End")
                    for (i in 0 until c.count) {
                        var name: String? = null
                        var phone = ""
                        val _id = c.getString(c.getColumnIndexOrThrow("_id"))
                        val thread_id = c.getString(c.getColumnIndexOrThrow("thread_id"))
                        val msg = c.getString(c.getColumnIndexOrThrow("body"))
                        val type = c.getString(c.getColumnIndexOrThrow("type"))
                        val timestamp = c.getString(c.getColumnIndexOrThrow("date"))
                        val read = c.getString(c.getColumnIndexOrThrow("date"))
                        phone = c.getString(c.getColumnIndexOrThrow("address"))
//                        name = CacheUtils.readFile(thread_id)
                        if (name == null) {
                            name = SmsUtils.getContactbyPhoneNumber(applicationContext, c.getString(c.getColumnIndexOrThrow("address")))
//                            CacheUtils.writeFile(thread_id, name)
                        }


                        val aux = SmsUtils.mappingInbox(_id, thread_id, name, phone, msg, type, timestamp, SmsUtils.converToTime(timestamp))
                        smsList.add(aux)
                        caller.runOnUiThread {
                            caller.methodChannel.invokeMethod(methods.KCOvList, aux)
                        }
                        c.moveToNext()
                    }
                }
                c.close()

            } catch (e: IllegalArgumentException) {
                e.printStackTrace()
            }
            Collections.sort(smsList, MapComparator(SmsUtils.KEY_TIMESTAMP, "dsc")) // Arranging sms by timestamp decending
            val purified = SmsUtils.removeDuplicates(smsList) // Removing duplicates from inbox & sent
            smsList.clear()
            smsList.addAll(purified)

// Updating cache data
            try {
                SmsUtils.createCachedFile(this@MainActivity, "flashSms", smsList)
            } catch (e: Exception) {
            }

//            Updating cache data

            return xml
        }

        override fun onPostExecute(xml: String) {
            if (!tmpList.equals(smsList)) {
//todo uncoment this
//                methodChannel.invokeMethod(methods.KList, smsList)
                /* adapter = InboxAdapter(this@MainActivity, smsList)
                 listView.setAdapter(adapter)
                 listView.setOnItemClickListener(object : AdapterView.OnItemClickListener {
                     fun onItemClick(parent: AdapterView<*>, view: View,
                                     position: Int, id: Long) {
                         val intent = Intent(this@MainActivity, Chat::class.java)
                         intent.putExtra("name", smsList[+position][SmsUtils.KEY_NAME])
                         intent.putExtra("address", tmpList.get(+position).get(SmsUtils.KEY_PHONE))
                         intent.putExtra("thread_id", smsList[+position][SmsUtils.KEY_THREAD_ID])
                         startActivity(intent)
                     }
                 })*/
            }


        }
    }


    internal inner class LoadChat(private val thread_id_main: Int, private val name: String) : AsyncTask<String, Void, String>() {
        var smsChatList = ArrayList<HashMap<String, String>>()
        var tmpChatList = ArrayList<HashMap<String, String>>()

        init {
            Log.d(tag, "loadChat")
            try {
                smsChatList = SmsUtils.readCachedFile(this@MainActivity, "flashSmsChat#$thread_id_main") as ArrayList<HashMap<String, String>>
                methodChannel.invokeMethod(methods.KChatList, smsChatList)
            } catch (e: Exception) {
            }

        }

        override fun doInBackground(vararg args: String): String {
            val xml = ""

            try {
                val uriInbox = Uri.parse("content://sms/inbox")
                val inbox = contentResolver.query(uriInbox, null, "thread_id=$thread_id_main", null, null)
                val uriSent = Uri.parse("content://sms/sent")
                val sent = contentResolver.query(uriSent, null, "thread_id=$thread_id_main", null, null)
                val c = MergeCursor(arrayOf(inbox, sent)) // Attaching inbox and sent sms



                if (c.moveToFirst()) {
                    for (i in 0 until c.count) {
                        var phone = ""
                        val _id = c.getString(c.getColumnIndexOrThrow("_id"))
                        val thread_id = c.getString(c.getColumnIndexOrThrow("thread_id"))
                        val msg = c.getString(c.getColumnIndexOrThrow("body"))
                        val type = c.getString(c.getColumnIndexOrThrow("type"))
                        val timestamp = c.getString(c.getColumnIndexOrThrow("date"))
                        phone = c.getString(c.getColumnIndexOrThrow("address"))

                        tmpChatList.add(SmsUtils.mappingInbox(_id, thread_id, name, phone, msg, type, timestamp, SmsUtils.converToTime(timestamp)))
                        c.moveToNext()
                    }
                }
                c.close()

            } catch (e: IllegalArgumentException) {
                e.printStackTrace()
            }

            Collections.sort(tmpChatList, MapComparator(SmsUtils.KEY_TIMESTAMP, "asc"))

            // Updating cache data
            try {
                SmsUtils.createCachedFile(this@MainActivity, "flashSmsChat#$thread_id_main", smsChatList)
            } catch (e: Exception) {
            }

            return xml
        }

        override fun onPostExecute(xml: String) {

            print("\n\npostexecute\n\n")
            if (!tmpChatList.equals(smsChatList)) {
                print("\n\npostenter\n\n")
//                smsList.clear()
//                smsList.addAll(tmpList)
//                adapter = ChatAdapter(this@Chat, smsList)
//                listView.setAdapter(adapter)
                methodChannel.invokeMethod(methods.KChatList, tmpChatList)
            }

        }
    }

}

class methods {
    companion object {
        const val FP = "firstOpen"
        const val SSms = "sendSms"
        const val RSms = "RetrieveAllSms"
        const val Dial = "newCall"
        const val KSmsI = "KotlinSmsIncomming"
        const val KList = "KotlinList"
        const val KCOvList = "KotlinChatOverviewList"
        const val KChatList = "KotlinChatList"
    }
}