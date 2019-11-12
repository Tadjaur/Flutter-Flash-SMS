package com.tadjaur.flash_sms

import android.content.Context
import org.dizitart.no2.Nitrite


class SmsDb {
    class Collection {
        companion object {
            const val messages = "MESSAGES"
        }
    }
    companion object {
        @Volatile
        private var INSTANCE: Nitrite? = null

        fun getInstance(context: Context): Nitrite {
            return INSTANCE ?: synchronized(this) {
                INSTANCE ?: buildNitriteDB(context).also { INSTANCE = it }
            }
        }

        private fun buildNitriteDB(context: Context): Nitrite {
            return Nitrite.builder()
                    .compressed()
                    .filePath(context.filesDir.path + "/sms.db")
                    .openOrCreate("chlid", "#com.tadjaur.flash_sms")
        }
    }

}