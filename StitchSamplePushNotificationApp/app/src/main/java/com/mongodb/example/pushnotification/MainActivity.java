package com.mongodb.example.pushnotification;

import android.support.annotation.NonNull;
import android.support.v7.app.AppCompatActivity;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.widget.CheckBox;
import android.widget.Toast;

import com.google.android.gms.tasks.OnCompleteListener;
import com.google.android.gms.tasks.OnSuccessListener;
import com.google.android.gms.tasks.Task;
import com.mongodb.stitch.android.StitchClient;
import com.mongodb.stitch.android.auth.Auth;
import com.mongodb.stitch.android.auth.AvailableAuthProviders;
import com.mongodb.stitch.android.auth.anonymous.AnonymousAuthProvider;
import com.mongodb.stitch.android.push.AvailablePushProviders;
import com.mongodb.stitch.android.push.gcm.GCMPushClient;

public class MainActivity extends AppCompatActivity {

    public static final String TOPIC_HOLIDAYS = "com.mongodb.example.pushnotification.holidays";
    public static final String TOPIC_QUOTES = "com.mongodb.example.pushnotification.quotes";

    private static final String TAG = "StitchPushNotification";

    private StitchClient stitchClient;

    private GCMPushClient pushClient;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        stitchClient = new StitchClient(this, "STICH-APP-ID");

        initLogin();

    }

    private void initLogin() {
        stitchClient.getAuthProviders().addOnCompleteListener(new OnCompleteListener<AvailableAuthProviders>() {
            @Override
            public void onComplete(@NonNull final Task<AvailableAuthProviders> task) {
                if (task.isSuccessful()) {
                    AvailableAuthProviders info = task.getResult();

                    if (info.hasAnonymous()) {
                        stitchClient.logInWithProvider(new AnonymousAuthProvider()).addOnCompleteListener(new OnCompleteListener<Auth>() {
                            @Override
                            public void onComplete(@NonNull final Task<Auth> task) {
                                if (task.isSuccessful()) {
                                    initGCMClient();
                                } else {
                                    Log.e(TAG, "Error logging in anonymously", task.getException());
                                    Toast.makeText(getApplicationContext(), "Error logging in anonymously.", Toast.LENGTH_LONG).show();
                                }
                            }
                        });
                    } else {
                        Log.e(TAG, "Enable Anonymous Login", task.getException());
                        Toast.makeText(getApplicationContext(), "You must enable Anonymous Login in Stitch.", Toast.LENGTH_LONG).show();
                    }
                } else {
                    Log.e(TAG, "Error getting authentication info", task.getException());
                    Toast.makeText(getApplicationContext(), "Error getting authentication info.", Toast.LENGTH_LONG).show();
                }
            }
        });
    }

    private void initGCMClient() {
        stitchClient.getPushProviders()
                .addOnSuccessListener(new OnSuccessListener<AvailablePushProviders>() {
            @Override
            public void onSuccess(final AvailablePushProviders availablePushProviders) {
                if (!availablePushProviders.hasGCM()) {
                    return;
                }
                pushClient = (GCMPushClient) stitchClient.getPush().forProvider(availablePushProviders.getGCM());
                pushClient.register().addOnCompleteListener(new OnCompleteListener<Void>() {
                    @Override
                    public void onComplete(@NonNull final Task<Void> task) {
                        if (!task.isSuccessful()) {
                            Log.d(TAG, "Registration failed: " + task.getException());
                            Toast.makeText(getApplicationContext(), "Error registering client for GCM.", Toast.LENGTH_LONG).show();
                            return;
                        }

                        Log.d(TAG, "Registration completed");
                        Toast.makeText(getApplicationContext(), "Successfully registered client for GCM.", Toast.LENGTH_SHORT).show();
                    }
                });
            }
        });
    }


    /** Called when the user subscribes to specific push notification topics.
     * The method is the onClick method for button2.
     * @param view
     */
    public void subscribeToTopic(View view) {

        if (!stitchClient.isAuthenticated()) {
            Log.e(TAG, "Not Logged In.");
            Toast.makeText(getApplicationContext(), "Error: Not logged in.", Toast.LENGTH_SHORT).show();
            return;
        }

        CheckBox chkboxHolidays = (CheckBox) findViewById(R.id.checkBox_holidays);

        if (chkboxHolidays.isChecked() ) {
            pushClient.subscribeToTopic(TOPIC_HOLIDAYS).addOnCompleteListener(new OnCompleteListener<Void>() {
                @Override
                public void onComplete(@NonNull final Task<Void> task) {
                    if (!task.isSuccessful()) {
                        Log.d(TAG, "Error subscribing to topic " + task.getException());
                        return;
                    }

                    Log.d(TAG, "Subscribed to topic Holidays");
                    Toast.makeText(getApplicationContext(), "Subscribed to topic Holidays.", Toast.LENGTH_LONG).show();
                }
            });
        } else {
            pushClient.unsubscribeFromTopic(TOPIC_HOLIDAYS).addOnCompleteListener(new OnCompleteListener<Void>() {
                @Override
                public void onComplete(@NonNull final Task<Void> task) {
                    if (!task.isSuccessful()) {
                        Log.d(TAG, "Error Unsubscribing to topic " + task.getException());
                        Toast.makeText(getApplicationContext(), "Error unsubscribing to topic Holidays.", Toast.LENGTH_LONG).show();
                        return;
                    }
                }
            });
        }

        CheckBox chkboxQuotes = (CheckBox) findViewById(R.id.checkBox_quotes);

        if (chkboxQuotes.isChecked()){
            pushClient.subscribeToTopic(TOPIC_QUOTES).addOnCompleteListener(new OnCompleteListener<Void>() {
                @Override
                public void onComplete(@NonNull final Task<Void> task) {
                    if (!task.isSuccessful()) {
                        Log.d(TAG, "Error subscribing to topic " + task.getException());
                        Toast.makeText(getApplicationContext(), "Error subscribing to topic.", Toast.LENGTH_LONG).show();
                        return;
                    }

                    Log.d(TAG, "Subscribed to topic Quotes.");
                    Toast.makeText(getApplicationContext(), "Subscribed to topic Quotes.", Toast.LENGTH_LONG).show();
                }

            });
        } else {
            pushClient.unsubscribeFromTopic(TOPIC_QUOTES).addOnCompleteListener(new OnCompleteListener<Void>() {
                @Override
                public void onComplete(@NonNull final Task<Void> task) {
                    if (!task.isSuccessful()) {
                        Log.d(TAG, "Error Unsubscribing to topic " + task.getException());
                        Toast.makeText(getApplicationContext(), "Error unsubscribing to topic Quotes.", Toast.LENGTH_LONG).show();
                        return;
                    }
                }

            });
        }

    }
}
