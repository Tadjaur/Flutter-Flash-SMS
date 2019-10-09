package com.tadjaur.flash_sms


import android.content.Context
import android.net.Uri
import android.provider.ContactsContract
import android.telephony.SmsManager
import java.io.IOException
import java.io.ObjectInputStream
import java.io.ObjectOutputStream
import java.text.SimpleDateFormat
import java.util.*

class SmsUtils {
    companion object {
        private const val _ID = "_id"
        private const val KEY_THREAD_ID = "thread_id"
        private const val KEY_NAME = "name"
        private const val KEY_PHONE = "phone"
        private const val KEY_MSG = "msg"
        private const val KEY_TYPE = "type"
        const val KEY_TIMESTAMP = "timestamp"
        private const val KEY_TIME = "time"

        fun converToTime(timestamp: String): String {
            val datetime = java.lang.Long.parseLong(timestamp)
            val date = Date(datetime)
            val formatter = SimpleDateFormat("dd/MM HH:mm")
            return formatter.format(date)
        }


        fun mappingInbox(_id: String, thread_id: String, name: String, phone: String, msg: String, type: String, timestamp: String, time: String): HashMap<String, String> {
            val map = HashMap<String, String>()
            map[_ID] = _id
            map[KEY_THREAD_ID] = thread_id
            map[KEY_NAME] = name
            map[KEY_PHONE] = phone
            map[KEY_MSG] = msg
            map[KEY_TYPE] = type
            map[KEY_TIMESTAMP] = timestamp
            map[KEY_TIME] = time
            return map
        }


        fun removeDuplicates(smsList: ArrayList<HashMap<String, String>>): ArrayList<HashMap<String, String>> {
            val gpList = ArrayList<HashMap<String, String>>()
            for (i in smsList.indices) {
                var available = false
                for (j in gpList.indices) {
                    if (Integer.parseInt(gpList[j][KEY_THREAD_ID]) == Integer.parseInt(smsList[i][KEY_THREAD_ID])) {
                        available = true
                        break
                    }
                }

                if (!available) {
                    smsList[i][_ID]?.let {
                        smsList[i][KEY_THREAD_ID]?.let { it1 ->
                            smsList[i][KEY_NAME]?.let { it2 ->
                                smsList[i][KEY_PHONE]?.let { it3 ->
                                    smsList[i][KEY_MSG]?.let { it4 ->
                                        smsList[i][KEY_TYPE]?.let { it5 ->
                                            smsList[i][KEY_TIMESTAMP]?.let { it6 ->
                                                smsList[i][KEY_TIME]?.let { it7 ->
                                                    mappingInbox(it, it1,
                                                            it2, it3,
                                                            it4, it5,
                                                            it6, it7)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }?.let { gpList.add(it) }
                }
            }
            return gpList
        }


        fun sendSMS(toPhoneNumber: String, smsMessage: String): Boolean {
            try {
                val smsManager = SmsManager.getDefault()
                smsManager.sendTextMessage(toPhoneNumber, null, smsMessage, null, null)
                return true
            } catch (e: Exception) {
                e.printStackTrace()
                return false
            }

        }

        fun getContactbyPhoneNumber(c: Context, phoneNumber: String): String {

            val uri = Uri.withAppendedPath(ContactsContract.PhoneLookup.CONTENT_FILTER_URI, Uri.encode(phoneNumber))
            val projection = arrayOf(ContactsContract.PhoneLookup.DISPLAY_NAME)
            val cursor = c.contentResolver.query(uri, projection, null, null, null)

            if (cursor == null) {
                return phoneNumber
            } else {
                var name = phoneNumber
                try {
                    if (cursor.moveToFirst()) {
                        name = cursor.getString(cursor.getColumnIndex(ContactsContract.PhoneLookup.DISPLAY_NAME))
                    }
                } finally {
                    cursor.close()
                }
                return name
            }
        }


        @Throws(IOException::class)
        fun createCachedFile(context: Context, key: String, dataList: ArrayList<HashMap<String, String>>) {
            val fos = context.openFileOutput(key, Context.MODE_PRIVATE)
            val oos = ObjectOutputStream(fos)
            oos.writeObject(dataList)
            oos.close()
            fos.close()
        }

        @Throws(IOException::class, ClassNotFoundException::class)
        fun readCachedFile(context: Context, key: String): Any {
            val fis = context.openFileInput(key)
            val ois = ObjectInputStream(fis)
            return ois.readObject()
        }
    }
}


class PermittionUtils{
    companion object{

    }
}