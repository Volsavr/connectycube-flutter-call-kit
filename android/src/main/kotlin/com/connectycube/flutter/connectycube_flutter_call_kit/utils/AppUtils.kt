package com.connectycube.flutter.connectycube_flutter_call_kit.utils

import android.app.ActivityManager
import android.app.KeyguardManager
import android.content.Context
import java.security.MessageDigest
import java.util.UUID
import android.util.Log
import com.connectycube.flutter.connectycube_flutter_call_kit.IncomingCallActivity

/**
 * Identify if the application is currently in a state where user interaction is possible. This
 * method is called when a remote message is received to determine how the incoming message should
 * be handled.
 *
 * @param context context.
 * @return True if the application is currently in a state where user interaction is possible,
 * false otherwise.
 */
fun isApplicationForeground(context: Context): Boolean {
    var keyguardManager = context.getSystemService(Context.KEYGUARD_SERVICE)
    if (keyguardManager == null) {
        return false
    } else {
        keyguardManager = keyguardManager as KeyguardManager
    }

    if (keyguardManager.isKeyguardLocked) {
        return false
    }

    var activityManager = context.getSystemService(Context.ACTIVITY_SERVICE)
    if (activityManager == null) {
        return false
    } else {
        activityManager = activityManager as ActivityManager
    }

    if(IncomingCallActivity.isActive){
        return false;
    }

    val appProcesses = activityManager.runningAppProcesses ?: return false
    val packageName = context.packageName
    for (appProcess in appProcesses) {
        Log.i("isApplicationForeground", "${appProcess.processName} -> ${appProcess.importance}")

        if (appProcess.importance == ActivityManager.RunningAppProcessInfo.IMPORTANCE_FOREGROUND
            && appProcess.processName == packageName
        ) {
            return true
        }
    }
    return false
}

fun generateMd5(input: String): String {
    val md = MessageDigest.getInstance("MD5")
    val digest = md.digest(input.toByteArray(Charsets.UTF_8))
    return digest.joinToString("") { String.format("%02x", it) }
}

/// generates uuid from random string using deprecated hash algorithm
/// should not be used in security critical functionality and
/// objects with long time to live
fun uuid(input: String?): String {
    if (input.isNullOrEmpty()) {
        return UUID.randomUUID().toString()
    }

    val str = generateMd5(input)

    // format string: NNNNNNNN-NNNN-NNNN-NNNN-NNNNNNNNNNNN
    val result = "${str.substring(0, 8)}-${str.substring(8, 12)}-${str.substring(12, 16)}-${str.substring(16, 20)}-${str.substring(20)}"

    return result
}