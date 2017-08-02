package com.mongodb.platespace.model;

import android.location.Location;
import android.os.Parcel;
import android.os.Parcelable;

import org.bson.Document;
import org.bson.types.ObjectId;

import java.util.ArrayList;

/**
 * A restaurant object
 */

public class Restaurant implements Parcelable
{
    private ObjectId mId;
    private double mNumberOfRates;
    private double mAverageRating;
    private Attributes mAttributes;
    private Location mLocation;
    private String mName;
    private String mAddress;
    private String mWebsite;
    private String mPhone;
    private String mImageUrl;
    private OpeningHours mOpeningHours;

    private double mDistance;

    /*
    * Helper class to keep all the field names in one place
    * */
    public class Field
    {
        public static final String ID = "_id";
        public static final String NAME = "name";
        public static final String ATTRIBUTES = "attributes";
        static final String NUMBER_OF_RATES = "numberOfRates";
        static final String AVERAGE_RATING = "averageRating";
        static final String OPENING_HOURS = "openingHours";
        static final String LOCATION = "location";
        static final String WEBSITE = "website";
        static final String IMAGE_URL = "image_url";
        static final String PHONE = "phone";
        static final String ADDRESS = "address";
        private static final String COORDINATES = "coordinates";
        private static final String DIST = "dist";
    }


    private Restaurant(Parcel in)
    {
        mId = (ObjectId) in.readSerializable();
        mNumberOfRates = in.readDouble();
        mAverageRating = in.readDouble();
        mAttributes = in.readParcelable(Attributes.class.getClassLoader());
        mLocation = in.readParcelable(Location.class.getClassLoader());
        mName = in.readString();
        mAddress = in.readString();
        mWebsite = in.readString();
        mPhone = in.readString();
        mImageUrl = in.readString();
        mOpeningHours = in.readParcelable(OpeningHours.class.getClassLoader());
        mDistance = in.readDouble();
    }

    public static final Creator<Restaurant> CREATOR = new Creator<Restaurant>()
    {
        @Override
        public Restaurant createFromParcel(Parcel in)
        {
            return new Restaurant(in);
        }

        @Override
        public Restaurant[] newArray(int size)
        {
            return new Restaurant[size];
        }
    };

    public static Restaurant fromDocument(Document document)
    {
        /*
        * Parse the restaurant object from the MongoDB document
        * */
        Restaurant restaurant = new Restaurant();

        try
        {
            restaurant.mId = document.getObjectId(Field.ID);

            /*
            Using 'Number' class will help avoid class cast exceptions in case the rating is sometimes an integer
            * and sometimes a double (data corruption in DB I suppose)
            * */
            Number numberOfRates = (Number) document.get(Field.NUMBER_OF_RATES);
            Number averageRatings = (Number) document.get(Field.AVERAGE_RATING);

            restaurant.mNumberOfRates = numberOfRates.doubleValue(); //we want the double value
            restaurant.mAverageRating = averageRatings.doubleValue(); //we want the double value
            restaurant.mOpeningHours = OpeningHours.fromDocument((Document) document.get(Field.OPENING_HOURS));
            restaurant.mLocation = locationFromDocument((Document) document.get(Field.LOCATION));
            restaurant.mAttributes = Attributes.fromDocument((Document) document.get(Field.ATTRIBUTES));
            restaurant.mWebsite = document.getString(Field.WEBSITE);
            restaurant.mImageUrl = document.getString(Field.IMAGE_URL);
            restaurant.mPhone = document.getString(Field.PHONE);
            restaurant.mAddress = document.getString(Field.ADDRESS);
            restaurant.mName = document.getString(Field.NAME);

            /*
            distance will only exist if we parsed the restaurant object after a geoNear command, where
            the distance was calculated
             */
            Number distance = (Number) document.get(Field.DIST);
            if (distance != null)
            {
                restaurant.mDistance = distance.doubleValue();
            }
        }
        catch (Exception e)
        {
            e.printStackTrace();
        }

        return restaurant;
    }

    private static Location locationFromDocument(Document document)
    {
        /*
        * parse the location object from the MongoDB document
        * */

        Object coordinates = document.get(Field.COORDINATES);
        Location location = new Location("");

        /*
        * note: in MongoDB the longitude is at position 0, and the latitude is in position 1
        * */
        location.setLongitude((Double) ((ArrayList) coordinates).get(0));
        location.setLatitude((Double) ((ArrayList) coordinates).get(1));
        return location;
    }

    private Restaurant()
    {
    }

    public double getDistance()
    {
        return mDistance;
    }

    public ObjectId getId()
    {
        return mId;
    }

    public double getAverageRating()
    {
        return mAverageRating;
    }

    public double getNumberOfRates()
    {
        return mNumberOfRates;
    }

    public Location getLocation()
    {
        return mLocation;
    }

    public String getName()
    {
        return mName;
    }

    public String getAddress()
    {
        return mAddress;
    }

    public String getWebsite()
    {
        return mWebsite;
    }

    public String getPhone()
    {
        return mPhone;
    }

    public String getImageUrl()
    {
        return mImageUrl;
    }

    public OpeningHours getOpeningHours()
    {
        return mOpeningHours;
    }

    public void setNumberOfRates(double numberOfRates)
    {
        mNumberOfRates = numberOfRates;
    }

    public void setAverageRating(double averageRating)
    {
        mAverageRating = averageRating;
    }

    @Override
    public boolean equals(Object o)
    {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;

        Restaurant that = (Restaurant) o;

        return mId != null ? mId.equals(that.mId) : that.mId == null;

    }

    @Override
    public int hashCode()
    {
        return mId != null ? mId.hashCode() : 0;
    }

    @Override
    public int describeContents()
    {
        return 0;
    }

    @Override
    public void writeToParcel(Parcel dest, int flags)
    {
        dest.writeSerializable(mId);
        dest.writeDouble(mNumberOfRates);
        dest.writeDouble(mAverageRating);
        dest.writeParcelable(mAttributes, flags);
        dest.writeParcelable(mLocation, flags);
        dest.writeString(mName);
        dest.writeString(mAddress);
        dest.writeString(mWebsite);
        dest.writeString(mPhone);
        dest.writeString(mImageUrl);
        dest.writeParcelable(mOpeningHours, flags);
        dest.writeDouble(mDistance);
    }
}
