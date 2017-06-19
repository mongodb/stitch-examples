package com.mongodb.solomo.application;

import android.app.Application;

import com.mongodb.solomo.R;
import uk.co.chrisjenx.calligraphy.CalligraphyConfig;

public class SoloMoApplication extends Application
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
