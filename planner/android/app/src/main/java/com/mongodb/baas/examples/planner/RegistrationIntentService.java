package com.mongodb.baas.examples.planner;

import android.app.IntentService;
import android.content.Intent;
import android.content.SharedPreferences;
import android.preference.PreferenceManager;
import android.support.v4.content.LocalBroadcastManager;

import com.google.android.gms.gcm.GoogleCloudMessaging;
import com.google.android.gms.iid.InstanceID;

import java.io.IOException;

public class RegistrationIntentService extends IntentService {

    public RegistrationIntentService() {
        super("RegistrationIntentService");
    }

    @Override
    protected void onHandleIntent(Intent intent) {
        final SharedPreferences sharedPreferences = PreferenceManager.getDefaultSharedPreferences(this);
        final InstanceID instanceID = InstanceID.getInstance(this);

        try {
            final String token = instanceID.getToken(getString(R.string.sender_id), GoogleCloudMessaging.INSTANCE_ID_SCOPE, null);
            sharedPreferences.edit().putString(Preferences.TOKEN, token).apply();
        } catch (final IOException e) {
            e.printStackTrace();
        }

        LocalBroadcastManager.getInstance(this).sendBroadcast(new Intent(Preferences.TOKEN));
    }
}
