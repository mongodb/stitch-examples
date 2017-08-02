package com.mongodb.platespace.application;

import android.app.Application;

import com.mongodb.platespace.R;
import uk.co.chrisjenx.calligraphy.CalligraphyConfig;

public class PlateSpaceApplication extends Application
{
    @Override
    public void onCreate()
    {
        super.onCreate();

        //default font to application using Calligraphy
        CalligraphyConfig.initDefault(new CalligraphyConfig.Builder()
                .setDefaultFontPath(getString(R.string.font_regular))
                .setFontAttrId(R.attr.fontPath)
                .build());
    }
}
