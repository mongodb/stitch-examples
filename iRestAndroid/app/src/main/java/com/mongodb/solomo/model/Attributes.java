package com.mongodb.solomo.model;

import android.os.Parcel;
import android.os.Parcelable;

import org.bson.Document;

/**
 * Additional attributes of a restaurants.
 */

public class Attributes implements Parcelable
{
    private boolean mVeganFriendly;
    private boolean mOpenOnWeekends;
    private boolean mHasParking;
    private boolean mHasWifi;

    /*
    Helper class to keep the field names in one place
    * */
    public class Field
    {
        public static final String VEGAN_FRIENDLY = "veganFriendly";
        public static final String OPEN_ON_WEEKENDS = "openOnWeekends";
        public static final String HAS_PARKING = "hasParking";
        public static final String HAS_WIFI = "hasWifi";
    }

    public Attributes()
    {
    }

    private Attributes(Parcel in)
    {
        mVeganFriendly = in.readByte() != 0;
        mOpenOnWeekends = in.readByte() != 0;
        mHasParking = in.readByte() != 0;
        mHasWifi = in.readByte() != 0;
    }

    public static final Creator<Attributes> CREATOR = new Creator<Attributes>()
    {
        @Override
        public Attributes createFromParcel(Parcel in)
        {
            return new Attributes(in);
        }

        @Override
        public Attributes[] newArray(int size)
        {
            return new Attributes[size];
        }
    };

    static Attributes fromDocument(Document document)
    {
        /*
        * Parse the class from the document received by MongoDB
        * */
        Attributes attributes = new Attributes();
        attributes.mVeganFriendly = document.getBoolean(Field.VEGAN_FRIENDLY);
        attributes.mOpenOnWeekends = document.getBoolean(Field.OPEN_ON_WEEKENDS);
        attributes.mHasParking = document.getBoolean(Field.HAS_PARKING);
        attributes.mHasWifi = document.getBoolean(Field.HAS_WIFI);
        return attributes;
    }

    public boolean isVeganFriendly()
    {
        return mVeganFriendly;
    }

    public boolean isOpenOnWeekends()
    {
        return mOpenOnWeekends;
    }

    public boolean hasParking()
    {
        return mHasParking;
    }

    public boolean hasWifi()
    {
        return mHasWifi;
    }

    public Attributes copy()
    {
        Attributes copy = new Attributes();
        copy.mVeganFriendly = isVeganFriendly();
        copy.mOpenOnWeekends = isOpenOnWeekends();
        copy.mHasWifi = hasWifi();
        copy.mHasParking = hasParking();
        return copy;
    }

    public boolean[] toArray()
    {
        /*
        Turn the attributes into an array of booleans.
        * This can be used later to show a multiple selection dialog
        * */

        boolean[] array = new boolean[5];
        array[1] = isVeganFriendly();
        array[2] = isOpenOnWeekends();
        array[3] = hasParking();
        array[4] = hasWifi();


        array[0] = isVeganFriendly() &&
                isOpenOnWeekends() &&
                hasParking() &&
                hasWifi();
        return array;
    }

    public static Attributes fromArray(boolean[] array)
    {
        /*
        * Construct an Attribute object from an array of booleans.
        * This can be used later when using a multiple selection dialog
        * */
        Attributes attributes = new Attributes();
        if (array[0]) //all categories have been selected
        {
            attributes.mVeganFriendly = true;
            attributes.mOpenOnWeekends = true;
            attributes.mHasParking = true;
            attributes.mHasWifi = true;
        }
        else
        {
            attributes.mVeganFriendly = array[1];
            attributes.mOpenOnWeekends = array[2];
            attributes.mHasParking = array[3];
            attributes.mHasWifi = array[4];
        }
        return attributes;
    }

    /*
    is one of the attributes is marked, we know we need to filter the restaurant list
     based on those attributes
     */
    public boolean filterEnabled()
    {
        return isVeganFriendly() ||
                isOpenOnWeekends() ||
                hasParking() ||
                hasWifi();
    }

    @Override
    public int describeContents()
    {
        return 0;
    }

    @Override
    public void writeToParcel(Parcel dest, int flags)
    {
        dest.writeByte((byte) (mVeganFriendly ? 1 : 0));
        dest.writeByte((byte) (mOpenOnWeekends ? 1 : 0));
        dest.writeByte((byte) (mHasParking ? 1 : 0));
        dest.writeByte((byte) (mHasWifi ? 1 : 0));
    }
}
