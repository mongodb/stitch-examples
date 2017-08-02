package com.mongodb.platespace.model;

import android.os.Parcel;
import android.os.Parcelable;
import android.util.Log;

import org.bson.Document;

import java.text.DateFormat;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.Date;
import java.util.Locale;

/**
 * Helper class to represent the opening hours of a restaurant.
 */

public class OpeningHours implements Parcelable
{
    private static final String LOG_TAG = OpeningHours.class.getSimpleName();
    private long mStart;
    private long mEnd;

    /*
    * Helper class to keep all the field names in one place
    * */
    private class Field
    {
        static final String TIME_FORMAT = "hhmm";
        static final String START = "start";
        static final String END = "end";
    }

    private OpeningHours()
    {
    }


    private OpeningHours(Parcel in)
    {
        mStart = in.readLong();
        mEnd = in.readLong();
    }

    @Override
    public void writeToParcel(Parcel dest, int flags)
    {
        dest.writeLong(mStart);
        dest.writeLong(mEnd);
    }

    @Override
    public int describeContents()
    {
        return 0;
    }

    public static final Creator<OpeningHours> CREATOR = new Creator<OpeningHours>()
    {
        @Override
        public OpeningHours createFromParcel(Parcel in)
        {
            return new OpeningHours(in);
        }

        @Override
        public OpeningHours[] newArray(int size)
        {
            return new OpeningHours[size];
        }
    };

    static OpeningHours fromDocument(Document document)
    {
        /*
        * parse the object from the document received by MongoDB.
        *
        * The format used for this sample app is hh:mm, so we parse it to 'time in millis' for later use instead of working with strings
        * */
        DateFormat sdf = new SimpleDateFormat(Field.TIME_FORMAT, Locale.ENGLISH);
        String start = document.getString(Field.START);
        String end = document.getString(Field.END);

        try
        {
            OpeningHours openingHours = new OpeningHours();
            openingHours.mStart = sdf.parse(start).getTime();
            openingHours.mEnd = sdf.parse(end).getTime();
            return openingHours;
        }
        catch (ParseException e)
        {
            e.printStackTrace();
            Log.e(LOG_TAG, "fromDocument: failed parsing opening hours", e);
        }

        return null;
    }

    public boolean isOpen()
    {
        Calendar now = Calendar.getInstance();
        Calendar checkDate = Calendar.getInstance();
        checkDate.setTime(new Date(mStart));

        /*
        Since the opening hours only have hours and minutes, we need to set it to the same date as 'now'
        * and only change the hours/minutes
        * */
        checkDate.set(Calendar.MINUTE, now.get(Calendar.MINUTE));
        checkDate.set(Calendar.HOUR_OF_DAY, now.get(Calendar.HOUR_OF_DAY));

        //if 'now' is between the start and the finish time, we'll consider it open
        return checkDate.getTimeInMillis() >= mStart && checkDate.getTimeInMillis() <= mEnd;
    }


}
