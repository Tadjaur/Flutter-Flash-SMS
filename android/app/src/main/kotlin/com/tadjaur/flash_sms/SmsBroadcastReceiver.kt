package com.tadjaur.flash_sms

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Telephony
import android.telephony.SmsMessage
import io.flutter.Log

class SmsBroadcastReceiver : BroadcastReceiver() {
    private var listener: Listener? = null

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Telephony.Sms.Intents.SMS_RECEIVED_ACTION) {
            Thread(Runnable {
            Log.e(tag, "new receiver")
            var smsSender = ""
            var smsBody = ""
            var serviceCenter: String? = ""
//            val msg:Document = Document("")
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
                for (smsMessage in Telephony.Sms.Intents.getMessagesFromIntent(intent)) {
                    smsSender = smsMessage.displayOriginatingAddress
                    smsBody += smsMessage.messageBody
                    serviceCenter = smsMessage.serviceCenterAddress
                    Utils.log(smsMessage, tag)

//                    msg.time = smsMessage.timestampMillis
//                    msg.status = smsMessage.status
//                    msg.phone = smsMessage.displayOriginatingAddress
                }
//                msg.msg = smsBody
            } else {
                val smsBundle = intent.extras
                if (smsBundle != null) {
                    val smsExtra = smsBundle.get("pdus") as Array<*>?
                    if (smsExtra == null) {
                        // Display some error to the user
                        Log.e(tag, "SmsBundle had no pdus key")
                        return@Runnable
                    }
                    val messages = arrayOfNulls<SmsMessage>(smsExtra.size)
                    Utils.log(messages)
                    for (i in messages.indices) {
                        messages[i] = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            SmsMessage.createFromPdu(smsExtra[i] as ByteArray, Telephony.Sms.Intents.SMS_RECEIVED_ACTION)
                        } else {
                            SmsMessage.createFromPdu(smsExtra[i] as ByteArray)
                        }
                        smsBody += messages[i]?.messageBody

//                        msg.time = messages[i]?.timestampMillis
//                        msg.status = messages[i]?.status
//                        msg.phone = messages[i]?.displayOriginatingAddress
                    }
                    serviceCenter = messages[0]?.serviceCenterAddress ?: ""
                    smsSender = messages[0]?.originatingAddress ?: "NULL"

//                    msg.msg = smsBody;
                }
            }
            android.util.Log.d("TAD::", "SENDER::$smsSender === BODY::$smsBody  === SERVICE::$serviceCenter")
            val smsObg = SmsDb.getInstance(context).getCollection(SmsDb.Collection.messages)
            println("$tag ::> ${smsObg.size()}")
//            smsObg.insertMessage(msg)
//            val a = smsObg.loadAllMessages()
//            a.forEach { m -> android.util.Log.d("TAD::", "phone: ${m.phone}; msg:${m.msg} time:${m.time}  phone: ") }
            if (listener != null) {
                android.util.Log.d("TAD::", "listener::$listener")
                listener!!.onTextReceived(smsSender, smsBody)
            }
            }).start()
        }
    }


    fun setListener(listener: Listener) {
        this.listener = listener
    }

    interface Listener {
        fun onTextReceived(sender: String, body: String)
    }

    companion object {
        private val tag = "TAD::SmsBroadcast"
    }

}
