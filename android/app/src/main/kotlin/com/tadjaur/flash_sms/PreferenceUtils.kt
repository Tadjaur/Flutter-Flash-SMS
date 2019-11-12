package com.tadjaur.flash_sms

import android.content.Context
import android.content.SharedPreferences
import com.tadjaur.flash_sms.Utils.Companion.log
import org.json.JSONArray
import org.json.JSONObject

class PreferenceUtils {
    internal class Key {
        companion object {
            const val conn = "connections"
            const val op = "operators"
        }
    }

    companion object {
        private const val PREFS_FILE = "com.tadjaur.flash_sms.pref_file"

        @Volatile
        private var prefs: SharedPreferences? = null

        fun getPrefs(ctx: Context): SharedPreferences {
            synchronized(this) {
                if (prefs == null) {
                    prefs = ctx.getSharedPreferences(PREFS_FILE, Context.MODE_PRIVATE)
                }
                return prefs!!
            }
        }

        fun set(key: String, value: Any, ctx: Context) {
            val data = when (value) {
                is ArrayList<*> -> "${JSONArray(value)}\\@A"
                is HashMap<*, *> -> "${JSONObject(value)}\\@H"
                is Boolean -> "$value\\@B"
                is Int -> "$value\\@I"
                is Double -> "$value\\@D"
                else -> "$value\\@S"
            }
            if (prefs == null) {
                synchronized(this) {
                    prefs = ctx.getSharedPreferences(PREFS_FILE, Context.MODE_PRIVATE)
                }
            }
            prefs!!.edit().putString(key, data).apply()
        }

        fun get(key: String, ctx: Context, default:Any? = null): Any? {
            synchronized(this) {
                if (prefs == null) {
                    prefs = ctx.getSharedPreferences(PREFS_FILE, Context.MODE_PRIVATE)
                }
                val res: String? = prefs!!.getString(key, "")
                log(res ?: "")
                return when (if (res != null && res.length > 3) res.substring(res.length - 3, res.length) else "") {
                    "\\@A" -> JSONArray(res!!.substring(0, res.length - 3))
                    "\\@B" -> res!!.substring(0, res.length - 3).toBoolean()
                    "\\@D" -> res!!.substring(0, res.length - 3).toDouble()
                    "\\@H" -> JSONObject(res!!.substring(0, res.length - 3))
                    "\\@I" -> res!!.substring(0, res.length - 3).toInt()
                    "\\@S" -> res!!.substring(0, res.length - 3)
                    else -> default
                }
            }
        }
    }
}