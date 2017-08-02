package com.mongodb.platespace.activities;

import android.content.Context;
import android.support.v7.app.AppCompatActivity;

import uk.co.chrisjenx.calligraphy.CalligraphyContextWrapper;

/**
 * Calligraphy makes dealing with fonts a lot easier
 */

public class CalligraphyActivity extends AppCompatActivity
{
    @Override
    protected void attachBaseContext(Context newBase)
    {
        super.attachBaseContext(CalligraphyContextWrapper.wrap(newBase));

    }
}
