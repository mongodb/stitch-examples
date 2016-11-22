package com.mongodb.baas.examples.planner;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.SharedPreferences;
import android.preference.PreferenceManager;
import android.support.v4.content.LocalBroadcastManager;
import android.support.v7.app.AppCompatActivity;
import android.os.Bundle;
import android.util.Log;
import android.widget.TextView;

import com.pubnub.api.PNConfiguration;
import com.pubnub.api.PubNub;
import com.pubnub.api.callbacks.PNCallback;
import com.pubnub.api.enums.PNPushType;
import com.pubnub.api.models.consumer.PNStatus;
import com.pubnub.api.models.consumer.push.PNPushAddChannelResult;

import java.util.Collections;

public class MainActivity extends AppCompatActivity {

    private static final String TAG = "MainActivity";

    private BroadcastReceiver _registrationBroadcastReceiver;
    private boolean _isReceiverRegistered;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.main_activity);

        final PNConfiguration pnConfiguration = new PNConfiguration()
                .setSubscribeKey(getString(R.string.sub_key));
        final PubNub pubnub = new PubNub(pnConfiguration);

        _registrationBroadcastReceiver = new BroadcastReceiver() {
            @Override
            public void onReceive(Context context, Intent intent) {
                SharedPreferences sharedPreferences =
                        PreferenceManager.getDefaultSharedPreferences(context);
                final String token = sharedPreferences.getString(Preferences.TOKEN, "");

                if (!token.isEmpty()) {

                    Log.d(TAG, "Token is " + token);

                    final String channelName = getString(R.string.channel);
                    pubnub.addPushNotificationsOnChannels()
                            .pushType(PNPushType.GCM)
                            .channels(Collections.singletonList(channelName))
                            .deviceId(token)
                            .async(new PNCallback<PNPushAddChannelResult>() {
                                @Override
                                public void onResponse(PNPushAddChannelResult result, PNStatus status) {
                                    if (status.isError()) {
                                        Log.d(TAG, "error happened while subscribing to push notification channel");
                                    } else {
                                        Log.d(TAG, "subscribed to push notification channel");
                                        ((TextView)findViewById(R.id.channel_name)).setText(channelName);
                                    }
                                }
                            });
                }
            }
        };
        registerReceiver();

        startService(new Intent(this, RegistrationIntentService.class));
    }

    @Override
    protected void onResume() {
        super.onResume();
        registerReceiver();
    }

    @Override
    protected void onPause() {
        LocalBroadcastManager.getInstance(this).unregisterReceiver(_registrationBroadcastReceiver);
        _isReceiverRegistered = false;
        super.onPause();
    }

    private void registerReceiver(){
        if(!_isReceiverRegistered) {
            LocalBroadcastManager.getInstance(this).registerReceiver(_registrationBroadcastReceiver,
                    new IntentFilter(Preferences.TOKEN));
            _isReceiverRegistered = true;
        }
    }
}
