package com.tadjaur.flash_sms


import android.content.Context
import android.database.Cursor
import android.net.Uri
import android.provider.ContactsContract
import java.io.*
import kotlin.collections.HashMap

class SmsUtils {
    companion object {

        private val listOfMemory: HashMap<String, ByteArray?> = HashMap()
        private const val ADDRESS = "address"
        private const val KEY_NAME = "name"
        private const val KEY_THUMB = "thumbnail"
        private const val KEY_PHOTO = "photo"


        @Throws(IOException::class)
        fun readBytes(inputStream: InputStream): ByteArray {
            val byteBuffer = ByteArrayOutputStream()
            val bufferSize = 1024
            val buffer = ByteArray(bufferSize)
            while (true) {
                val len = inputStream.read(buffer)
                if (len == -1) {
                    break
                }
                byteBuffer.write(buffer, 0, len)
            }
            return byteBuffer.toByteArray()
        }

        fun hashSmsCursorLine(c: Cursor, nameTab: Array<String>): HashMap<String, Any?> {
            val map = HashMap<String, Any?>()
            for (idx in 0 until nameTab.size) {
                val column = nameTab[idx]
                val value = c.getString(idx) ?: ""
                map[column] = value
                if (column == ADDRESS) {
                    val ctx = MainActivity.mainActivity.applicationContext
                    val tp = getContactByPhoneNumber(ctx, value)
                    map[KEY_NAME] = tp.first
                    if (listOfMemory.containsKey(tp.second)) {
                        map[KEY_THUMB] = listOfMemory[tp.second]
                    } else if (tp.second.isNotBlank()) {
                        val uri = Uri.parse(tp.second)
                        val input = ctx.contentResolver.openAssetFileDescriptor(uri, "r")?.createInputStream()
                        if (input == null) {
                            listOfMemory[tp.second] = null
                        } else {
                            listOfMemory[tp.second] = readBytes(input)
                        }
                        map[KEY_THUMB] = listOfMemory[tp.second]
                    }
                    if (listOfMemory.containsKey(tp.third)) {
                        map[KEY_PHOTO] = listOfMemory[tp.third]
                    } else if (tp.third.isNotBlank()) {
                        val uri = Uri.parse(tp.third)
                        val input = ctx.contentResolver.openAssetFileDescriptor(uri, "r")?.createInputStream()
                        if (input == null) {
                            listOfMemory[tp.third] = null
                        } else {
                            listOfMemory[tp.third] = readBytes(input)
                        }
                        map[KEY_PHOTO] = listOfMemory[tp.third]
                    }
                }
            }
            return map
        }


        fun getContactByPhoneNumber(c: Context, phoneNumber: String): ThreePair {

            val uri = Uri.withAppendedPath(ContactsContract.PhoneLookup.CONTENT_FILTER_URI, Uri.encode(phoneNumber))
            val projection = arrayOf(ContactsContract.PhoneLookup.DISPLAY_NAME, ContactsContract.PhoneLookup.PHOTO_THUMBNAIL_URI, ContactsContract.PhoneLookup.PHOTO_URI)
            val cursor = c.contentResolver.query(uri, projection, null, null, null)

            return if (cursor == null) {
                ThreePair(phoneNumber, "", "")
            } else {
                var name = phoneNumber
                var photo = ""
                var thumbnail = ""
                cursor.use { curs ->
                    if (curs.moveToFirst()) {
                        name = curs.getString(curs.getColumnIndex(ContactsContract.PhoneLookup.DISPLAY_NAME))
                        photo = curs.getString(curs.getColumnIndex(ContactsContract.PhoneLookup.PHOTO_URI))
                                ?: ""
                        thumbnail = curs.getString(curs.getColumnIndex(ContactsContract.PhoneLookup.PHOTO_THUMBNAIL_URI))
                                ?: ""
                    }
                }
                ThreePair(name, thumbnail, photo)
            }
        }

//
//        @Throws(IOException::class)
//        fun createCachedFile(context: Context, key: String, dataList: ArrayList<HashMap<String, String>>) {
//            val fos = context.openFileOutput(key, Context.MODE_PRIVATE)
//            val oos = ObjectOutputStream(fos)
//            oos.writeObject(dataList)
//            oos.close()
//            fos.close()
//        }

        /*@Throws(IOException::class, ClassNotFoundException::class)
        fun readCachedFile(context: Context, key: String): Any {
            val fis = context.openFileInput(key)
            val ois = ObjectInputStream(fis)
            return ois.readObject()
        }*/
    }
}