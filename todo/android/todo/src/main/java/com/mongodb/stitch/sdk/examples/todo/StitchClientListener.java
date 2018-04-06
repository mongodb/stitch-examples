package com.mongodb.stitch.sdk.examples.todo;

import com.mongodb.stitch.android.StitchClient;


// Interface that Activities should inherit when they need a StitchClient
public interface StitchClientListener {

    // Method that will be called once in an Activity's
    // lifetime with an initialized StitchClient
    void onReady(StitchClient stitchClient);
}

