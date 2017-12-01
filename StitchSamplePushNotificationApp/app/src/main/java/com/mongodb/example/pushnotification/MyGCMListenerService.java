package com.mongodb.example.pushnotification;

import android.app.Notification;
import android.app.NotificationManager;
import android.content.Context;
import android.os.Bundle;
import android.util.Log;

import com.mongodb.stitch.android.push.PushMessage;
import com.mongodb.stitch.android.push.gcm.GCMListenerService;


public class MyGCMListenerService extends GCMListenerService {

    public void onPushMessageReceived(PushMessage message) {
        super.onPushMessageReceived(message);

        Bundle notificationData = (Bundle)message.getRawData().get("notification");
        String notificationMsg = notificationData.getString("body");
        Log.d("Received message ", notificationMsg);

        // By default, notifications will only appear if the app is in the background.
        // Create a new notification here to show in case the app is in the foreground.
        Notification.Builder notificationBuilder;
        NotificationManager manager =
                (NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);
        if (android.os.Build.VERSION.SDK_INT >= 26) {
            notificationBuilder = new Notification.Builder(getApplicationContext(), "channel_id");
        } else {
            notificationBuilder = new Notification.Builder(getApplicationContext());
        }

        notificationBuilder.setContentTitle("Stitch Sample Push Notification App")
                .setContentText(notificationMsg)
                .setSmallIcon(R.mipmap.ic_launcher);

        manager.notify(1, notificationBuilder.build());
    }
}
