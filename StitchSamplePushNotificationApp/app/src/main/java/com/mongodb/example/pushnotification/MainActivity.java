package com.mongodb.example.pushnotification;

import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.content.Context;
import android.support.annotation.NonNull;
import android.support.v7.app.AppCompatActivity;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.widget.CheckBox;
import android.widget.ProgressBar;
import android.widget.Toast;

import com.google.android.gms.tasks.Continuation;
import com.google.android.gms.tasks.OnCompleteListener;
import com.google.android.gms.tasks.Task;

import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.iid.FirebaseInstanceId;
import com.mongodb.stitch.android.core.Stitch;
import com.mongodb.stitch.android.core.StitchAppClient;
import com.mongodb.stitch.android.core.auth.StitchUser;
import com.mongodb.stitch.android.services.fcm.FcmServicePushClient;
import com.mongodb.stitch.core.auth.providers.anonymous.AnonymousCredential;


public class MainActivity extends AppCompatActivity {

    public static final String TOPIC_HOLIDAYS = "holidays";
    public static final String TOPIC_QUOTES = "quotes";
    public static final String TOPIC_EVENTS = "events";

    private static final String TAG = "StitchPushNotification";

    private StitchAppClient stitchClient;
    private ProgressBar progressBar;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        this.stitchClient = Stitch.getDefaultAppClient();

        final FcmServicePushClient pushClient =
                this.stitchClient.getPush().getClient(FcmServicePushClient.Factory, "gcm");

        progressBar = (ProgressBar)findViewById(R.id.progress_bar);
        progressBar.setIndeterminate(true);

        final View mainView = findViewById(R.id.mainLayout);
        mainView.setVisibility(View.INVISIBLE);

        if (android.os.Build.VERSION.SDK_INT >= 26) {
            // For Android SDK 26 and above, it is necessary to create a channel to create notifications.
            NotificationManager manager =
                    (NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);
            NotificationChannel channel = new NotificationChannel("channel_id",
                    "channel_name", NotificationManager.IMPORTANCE_HIGH);
            manager.createNotificationChannel(channel);
        }

        // Log in and unsubscribe from topics.
        stitchClient.getAuth().loginWithCredential(new AnonymousCredential()
        ).continueWithTask(new Continuation<StitchUser, Task<Void>>() {
           @Override
           public Task<Void> then(@NonNull Task<StitchUser> task) throws Exception {
               return pushClient.register(FirebaseInstanceId.getInstance().getToken());
           }
       }).continueWithTask(new Continuation<Void, Task<Void>>() {
            @Override
            public Task<Void> then(@NonNull Task<Void> task) throws Exception {
                return FirebaseMessaging.getInstance().unsubscribeFromTopic(TOPIC_HOLIDAYS);
            }
        }).continueWithTask(new Continuation<Void, Task<Void>>() {
            @Override
            public Task<Void> then(@NonNull Task<Void> task) throws Exception {
                return FirebaseMessaging.getInstance().unsubscribeFromTopic(TOPIC_QUOTES);
            }
        }).continueWithTask(new Continuation<Void, Task<Void>>() {
            @Override
            public Task<Void> then(@NonNull Task<Void> task) throws Exception {
                return FirebaseMessaging.getInstance().unsubscribeFromTopic(TOPIC_EVENTS);
            }
        }).addOnCompleteListener(new OnCompleteListener<Void>() {
            @Override
            public void onComplete(@NonNull final Task<Void> task) {
                if (!task.isSuccessful()) {
                    Log.d(TAG, "Registration failed: " + task.getException());
                    Toast.makeText(getApplicationContext(), "Error registering client for Firebase.", Toast.LENGTH_LONG).show();
                    return;
                }

                Log.d(TAG, "Registration completed");
                Toast.makeText(getApplicationContext(), "Successfully registered client for Firebase.", Toast.LENGTH_SHORT).show();
                progressBar.setVisibility(View.INVISIBLE);
                mainView.setVisibility(View.VISIBLE);
            }
        });
    }

    /** Called when the user subscribes to specific push notification topics.
     * The method is the onClick method.
     * @param view
     */
    public void toggleSubscription(View view) {

        if (!stitchClient.getAuth().isLoggedIn()) {
            Log.e(TAG, "Not Logged In.");
            Toast.makeText(getApplicationContext(), "Error: Not logged in.", Toast.LENGTH_SHORT).show();
            return;
        }

        CheckBox checkBox = (CheckBox) view;
        final String topic = (String)checkBox.getText();
        Log.d(TAG, (String)checkBox.getText());

        if (checkBox.isChecked()) {
            FirebaseMessaging.getInstance().subscribeToTopic(topic).addOnCompleteListener(new OnCompleteListener<Void>() {
                @Override
                public void onComplete(@NonNull final Task<Void> task) {
                    if (!task.isSuccessful()) {
                        Log.d(TAG, "Error subscribing to topic " + task.getException());
                        return;
                    }

                    Log.d(TAG, "Subscribed to topic " + topic);
                    Toast.makeText(getApplicationContext(), "Subscribed to topic " + topic, Toast.LENGTH_LONG).show();
                }
            });
        }
        else {
            FirebaseMessaging.getInstance().unsubscribeFromTopic(topic).addOnCompleteListener(new OnCompleteListener<Void>() {
                @Override
                public void onComplete(@NonNull final Task<Void> task) {
                    if (!task.isSuccessful()) {
                        Log.d(TAG, "Error unsubscribing from topic " + task.getException());
                        return;
                    }

                    Log.d(TAG, "Unsubscribed from topic " + topic);
                    Toast.makeText(getApplicationContext(), "Unsubscribed from topic " + topic, Toast.LENGTH_LONG).show();
                }
            });
        }
    }
}
