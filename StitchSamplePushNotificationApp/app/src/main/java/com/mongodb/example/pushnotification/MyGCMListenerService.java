package com.mongodb.example.pushnotification;

import android.util.Log;

import com.mongodb.stitch.android.push.PushMessage;
import com.mongodb.stitch.android.push.gcm.GCMListenerService;


public class MyGCMListenerService extends GCMListenerService {

    public void onPushMessageReceived(PushMessage message) {
        Log.d("MyGCMListenerServiceL::", "Received Message" );
    }
}
