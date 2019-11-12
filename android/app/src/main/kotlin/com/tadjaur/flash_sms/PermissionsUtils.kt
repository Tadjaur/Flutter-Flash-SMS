package com.tadjaur.flash_sms

import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.support.v4.app.ActivityCompat
import android.support.v4.content.ContextCompat
import com.tadjaur.flash_sms.Utils.Companion.log

class PermissionsUtils {
    companion object {
        private const val tag = "PermissionsUtils"
        const val code = 99

        const val S_SMS = android.Manifest.permission.SEND_SMS
        const val R_SMS = android.Manifest.permission.READ_SMS
        const val R_CONTACTS = android.Manifest.permission.READ_CONTACTS
        const val W_CONTACTS = android.Manifest.permission.WRITE_CONTACTS
        const val VIB = android.Manifest.permission.VIBRATE
        const val CALL_PHONE = android.Manifest.permission.CALL_PHONE
        const val Rv_SMS = android.Manifest.permission.RECEIVE_SMS
        const val R_P_State = android.Manifest.permission.READ_PHONE_STATE


        private fun isPermissionGranted(context: Context, permission: String): Boolean {
            val v1 = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                context.checkSelfPermission(permission)
            } else {
                ContextCompat.checkSelfPermission(context, permission)
            }
            val v2 = PackageManager.PERMISSION_GRANTED
            return v1 == v2
        }

        fun checkAll(context: Context, permissions: Array<String>, make: Boolean = false, activity: Activity? = null): Boolean {
            for (i in 0 until permissions.size) {
                if (!isPermissionGranted(context, permissions[i])) {
                    if (make) {
                        requestPermission(activity!!, permissions, code)
                    }
                    return false
                }
            }
            return true
        }

        /**
         * Do operation on permissionResult
         *
         * @param requestCode the code of the request
         * @param permissions list of permission requested
         * @param grantResults list of grant
         * @param runnable
         * @param cancelRunnable
         * */
        fun onResult(requestCode: Int,
                     permissions: Array<String>,
                     grantResults: IntArray,
                     runnable:Runnable,
                     cancelRunnable:Runnable? = null,
                     deniedRunnable:Runnable? = null) {
            when (requestCode) {
                code -> {
                    // If request is cancelled, the result arrays are empty.
                    if (grantResults.isNotEmpty()) {
                        for (i in 0 until grantResults.count()) {
                            if (grantResults[i] != PackageManager.PERMISSION_GRANTED) {
                                log("somme permission are denied -> ${permissions[i]}", tag)
                                deniedRunnable?.run()
                                return
                            }
                        }
                        runnable.run()
                    }else{
                        cancelRunnable?.run()
                    }
                    return
                }
            }

        }
        fun requestPermission(activity: Activity, permissions: Array<String>, code: Int) {
            if (ActivityCompat.shouldShowRequestPermissionRationale(activity, android.Manifest.permission.SEND_SMS)) {
                // You may display a non-blocking explanation here, read more in the documentation:
                // https://developer.android.com/training/permissions/requesting.html
            }
            ActivityCompat.requestPermissions(activity, permissions, code)
        }
    }
}