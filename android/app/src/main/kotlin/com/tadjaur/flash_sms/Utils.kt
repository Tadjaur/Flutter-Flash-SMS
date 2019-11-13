package com.tadjaur.flash_sms


import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.support.v4.content.ContextCompat
import android.telephony.SmsManager
import android.telephony.SubscriptionManager
import android.telephony.TelephonyManager
import io.flutter.embedding.engine.FlutterShellArgs

class Utils {
    companion object {
        private const val tag = "TAD::Utils::"
        /**
         * Return the list of mobile operator if exist.
         *
         * @param ctx the [Context] of the application
         * @param call represent the method to call for each operator get
         * */
        fun getOperators(ctx: Context, call: (HashMap<String, String>) -> Any? = { _ -> null }): ArrayList<HashMap<String, String>> {
            var doOldMethod = true
            val res: ArrayList<HashMap<String, String>> = arrayListOf()
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP_MR1) {
                val simManager: SubscriptionManager = ctx.getSystemService(Context.TELEPHONY_SUBSCRIPTION_SERVICE) as SubscriptionManager
                if (PackageManager.PERMISSION_GRANTED != ContextCompat.checkSelfPermission(ctx, android.Manifest.permission.READ_PHONE_STATE)) {
                    log("permission denied")
                    return res
                }
                val simCount: Int = simManager.activeSubscriptionInfoCount
                if (simCount > 1) {
                    doOldMethod = false
                    val simOpeatorList = simManager.activeSubscriptionInfoList
                    var idx = 0
                    while (idx < simCount) {
                        println(simOpeatorList[idx])
                        val op: HashMap<String, String> = hashMapOf()
                        op["id"] = simOpeatorList[idx].subscriptionId.toString()
                        op["name"] = simOpeatorList[idx].carrierName.toString()
                        op["country"] = simOpeatorList[idx].countryIso.toString()
                        res.add(op)
                        call(op)
                        idx++
                    }
                }
            }
            if (doOldMethod) {
                val telephony: TelephonyManager = ctx.getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager

                val state = telephony.simState
                if (state == TelephonyManager.SIM_STATE_READY) {
                    val op: HashMap<String, String> = HashMap()
                    op["id"] = "-1"
                    op["name"] = telephony.simOperatorName
                    op["country"] = telephony.simCountryIso
                    call(op)
                    res.add(op)
                }
            }

            return res
        }


        /**
         * send and sms to the specified phoneNumber
         *
         * @param ctx the [Context] of the application
         * @param message the message that we want to send
         * @param phoneNumber the number of the destination
         * @param operatorName the name of the operator we want to send a sms or the the default
         * operator if set to null
         * @param simId the sim position of the operator
         * @param sentIntentId the id of the intent that will maybe catch the sent action
         * @param deliveredIntentId the id of the intent that will maybe catch the deliver action
         *
         * @return [Boolean] that represent if message was send or not
         * */
        fun sendSMS(ctx: Context, message: String?, phoneNumber: String?, operatorName: String? = "#default", simId: Int = -1, sentIntentId: String, deliveredIntentId: String): Boolean {
            if (message == null || phoneNumber == null || operatorName == null)
                return false
            SmsReceivers.register(ctx, sentIntentId, deliveredIntentId)
            val sentIntent = PendingIntent.getBroadcast(ctx, 0, Intent(sentIntentId), 0)
            val deliverIntent = PendingIntent.getBroadcast(ctx, 0, Intent(deliveredIntentId), 0)
            var send = false
            fun sendToDefault(){
                println("sending sms...")
                SmsManager.getDefault().sendTextMessage(phoneNumber, null, message, sentIntent, deliverIntent)
                send = true
            }
            if(operatorName == "#default"){
                sendToDefault()
            }else{
                fun callBack(operator: HashMap<String, String>) {
                    if (send) return
                    println(operator)
                    if (operator["id"]?.toInt() == -1) {
                        if (operator["name"]?.toLowerCase() == operatorName.toLowerCase()) {
                            sendToDefault()
                        }
                    } else {
                        if (operator["name"]?.toLowerCase() == operatorName.toLowerCase() && (simId == -1 || simId == operator["id"]?.toInt())) {
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP_MR1) {
                                println("sending sms...")
                                SmsManager.getSmsManagerForSubscriptionId(operator["id"]!!.toInt()).sendTextMessage(phoneNumber, null, message, sentIntent, deliverIntent)
                                send = true
                            }
                        }

                    }
                }
                getOperators(ctx, ::callBack)
            }

            return send
        }


        fun log(msg:Any, id:String = tag, vararg args: Any?){
            print("TAD:: $id >> ")
            println(msg)
            for (i in 0 until args.size){
                print("args[$i]")
                println(args[i])
            }
        }


    }
}

class ThreePair(val first:String, val second:String, val third:String)