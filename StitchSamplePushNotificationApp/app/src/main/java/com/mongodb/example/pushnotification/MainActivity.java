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
import com.mongodb.stitch.android.StitchClient;

import com.mongodb.stitch.android.auth.anonymous.AnonymousAuthProvider;
import com.mongodb.stitch.android.push.AvailablePushProviders;
import com.mongodb.stitch.android.push.gcm.GCMPushClient;


public class MainActivity extends AppCompatActivity implements StitchClientListener {

    public static final String TOPIC_HOLIDAYS = "holidays";
    public static final String TOPIC_QUOTES = "quotes";
    public static final String TOPIC_EVENTS = "events";

    private static final String TAG = "StitchPushNotification";

    private StitchClient stitchClient;
    private GCMPushClient pushClient;
    private ProgressBar progressBar;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        StitchClientManager.initialize(this.getApplicationContext());
        StitchClientManager.registerListener(this);
    }

    @Override
    public void onReady(StitchClient _client) {
        this.stitchClient = _client;

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
        stitchClient.logInWithProvider(new AnonymousAuthProvider())
                .continueWithTask(new Continuation<String, Task<AvailablePushProviders>>() {
                    @Override
                    public Task<AvailablePushProviders> then(@NonNull Task<String> task) throws Exception {
                        return stitchClient.getPushProviders();
                    }
        }).continueWithTask(new Continuation<AvailablePushProviders, Task<Void>>() {
            @Override
            public Task<Void> then(@NonNull Task<AvailablePushProviders> task) throws Exception {
                pushClient = (GCMPushClient) stitchClient.getPush().forProvider(task.getResult().getGCM());
                return pushClient.register();
            }
        }).continueWithTask(new Continuation<Void, Task<Void>>() {
            @Override
            public Task<Void> then(@NonNull Task<Void> task) throws Exception {
                return pushClient.unsubscribeFromTopic(TOPIC_HOLIDAYS);
            }
        }).continueWithTask(new Continuation<Void, Task<Void>>() {
            @Override
            public Task<Void> then(@NonNull Task<Void> task) throws Exception {
                return pushClient.unsubscribeFromTopic(TOPIC_QUOTES);
            }
        }).continueWithTask(new Continuation<Void, Task<Void>>() {
            @Override
            public Task<Void> then(@NonNull Task<Void> task) throws Exception {
                return pushClient.unsubscribeFromTopic(TOPIC_EVENTS);
            }
        }).addOnCompleteListener(new OnCompleteListener<Void>() {
            @Override
            public void onComplete(@NonNull final Task<Void> task) {
                if (!task.isSuccessful()) {
                    Log.d(TAG, "Registration failed: " + task.getException());
                    Toast.makeText(getApplicationContext(), "Error registering client for GCM.", Toast.LENGTH_LONG).show();
                    return;
                }

                Log.d(TAG, "Registration completed");
                Toast.makeText(getApplicationContext(), "Successfully registered client for GCM.", Toast.LENGTH_SHORT).show();
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

        if (!stitchClient.isAuthenticated()) {
            Log.e(TAG, "Not Logged In.");
            Toast.makeText(getApplicationContext(), "Error: Not logged in.", Toast.LENGTH_SHORT).show();
            return;
        }

        CheckBox checkBox = (CheckBox) view;
        final String topic = (String)checkBox.getText();
        Log.d(TAG, (String)checkBox.getText());

        if (checkBox.isChecked()) {
            pushClient.subscribeToTopic(topic).addOnCompleteListener(new OnCompleteListener<Void>() {
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
            pushClient.unsubscribeFromTopic(topic).addOnCompleteListener(new OnCompleteListener<Void>() {
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
