package com.connectycube.flutter.connectycube_flutter_call_kit

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import com.connectycube.flutter.connectycube_flutter_call_kit.utils.ContextHolder
import com.google.firebase.messaging.RemoteMessage
import org.json.JSONObject
import com.connectycube.flutter.connectycube_flutter_call_kit.utils.uuid
import com.connectycube.flutter.connectycube_flutter_call_kit.utils.isApplicationForeground


class ConnectycubeFCMReceiver : BroadcastReceiver() {
    private val TAG = "ConnectycubeFCMReceiver"

    override fun onReceive(context: Context?, intent: Intent?) {
        Log.d(TAG, "broadcast received for message")

        ContextHolder.applicationContext = context!!.applicationContext

        if (intent!!.extras == null) {
            Log.d(
                TAG,
                "broadcast received but intent contained no extras to process RemoteMessage. Operation cancelled."
            )
            return
        }

        val remoteMessage = RemoteMessage(intent.extras!!)

        Log.d(
                TAG,
                "RemoteMessage: : ${remoteMessage.data.toMap()}"
        )

        val data = remoteMessage.data
        if (data.containsKey("type")) {
            when (data["type"]) {
                /*"cc_call_start" -> {
                    processInviteCallEvent(context.applicationContext, data)
                }*/

                //Handle only call_end notification, call_start handled in flutter
                "call_end" -> {
                    processEndCallEvent(context.applicationContext, data)
                }

                /*"rejectCall" -> {
                    processEndCallEvent(context.applicationContext, data)
                }*/
            }

        }
    }

    private fun processEndCallEvent(applicationContext: Context, data: Map<String, String>) {
        Log.d(TAG, "[processEndCallEvent]")

        val callId = data["from_tag"] ?: return
        val callUuid = uuid(callId)

        processCallEnded(applicationContext, callUuid)
    }

    private fun processInviteCallEvent(applicationContext: Context, data: Map<String, String>) {
        Log.d(TAG, "[processInviteCallEvent]")
        val callId = data["from_tag"]

        if (callId == null || CALL_STATE_UNKNOWN != getCallState(
                applicationContext,
                callId
            )
        ) {
            Log.d(TAG, "[processInviteCallEvent] callId == null || CALL_STATE_UNKNOWN != getCallState(applicationContext, callId)")
            return
        }

        val callUuid = uuid(callId)

        var displayName = data["from_display_name"]
        Log.d(TAG, "[processInviteCallEvent] from_display_name: ${displayName}")

        var callerId = data["from_user"]
        Log.d(TAG, "[processInviteCallEvent] from_user: ${callerId}")

        //fallback to caller identity
        if (displayName == null || displayName.isEmpty()) {
            displayName = callerId
        }

        // fallback to default
        if (displayName == null || displayName.isEmpty()) {
            displayName = "Unknown"
        }

        Log.d(TAG, "[processInviteCallEvent] selected display name: ${displayName}")

        var callOpponents = arrayListOf(1)
        val mapWithValues = mapOf("phoneNumber" to callerId, "displayName" to displayName)
        val userInfo = JSONObject(mapWithValues).toString()

        notifyAboutIncomingCall(
                applicationContext,
                callUuid,
                0,
                0,
                displayName,
                callOpponents,
                null,
                userInfo
        )

       if(!isApplicationForeground(applicationContext)) {
           showCallNotification(
                   applicationContext,
                   callUuid,
                   0,
                   0,
                   displayName,
                   callOpponents,
                   null,
                   userInfo
           )
       }

        saveCallState(applicationContext, callUuid, CALL_STATE_PENDING)
        saveCallData(applicationContext, callUuid, data)
        saveCallId(applicationContext, callUuid)
    }
}