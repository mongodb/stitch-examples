package com.mongodb.platespace.model;

import android.util.Log;

import org.bson.Document;
import org.bson.types.ObjectId;

import java.io.Serializable;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;

import static com.facebook.GraphRequest.TAG;

/**
 * Class that represent a review for a restaurant
 */

public class Review implements Serializable
{

    //The time format we want for this sample app UI(i.e 04 Feb 2017)
    private SimpleDateFormat mSimpleDateFormat = new SimpleDateFormat("dd MMM yyyy", Locale.getDefault());

    private ObjectId mId;
    private String mName;
    private String mComment;
    private Date mDate;
    private int mRate;

    private boolean isEditable;

    /*
    * Helper class to keep all the field names in one place
    * */
    public class Field
    {
        public static final String ID = "_id";
        public static final String OWNER_ID = "owner_id";
        public static final String RESTAURANT_ID = "restaurantId";
        public static final String COMMENT = "comment";
        public static final String DATE = "dateOfComment";
        public static final String NAME_OF_REVIEWER = "nameOfCommenter";
        public static final String RATE = "rate";
    }


    public static Review fromDocument(Document document)
    {
        /*
        * Parse the object from MongoDB document
        * */

        Review review = new Review();
        review.mId = document.getObjectId(Field.ID);
        review.mComment = document.getString(Field.COMMENT);
        review.mDate = document.getDate(Field.DATE);
        review.mName = document.getString(Field.NAME_OF_REVIEWER);

        /*
        * Avoid class cast exceptions for integer/double in case something went wrong
        * */
        Number rate = (Number) document.get(Field.RATE);

        /*
        For this sample app scheme, there is a possibility that a user left a comment but not a rate,
        so we need nullity check.
         */
        review.mRate = rate == null ? 0 : rate.intValue();
        return review;
    }

    @Override
    public boolean equals(Object o)
    {
        /*
        * We consider reviews equal if they have the same MongoDB id
        * */

        if (this == o)
        {
            return true;
        }
        if (o == null || getClass() != o.getClass())
        {
            return false;
        }

        Review review = (Review) o;

        return mId.equals(review.mId);

    }

    @Override
    public int hashCode()
    {
        return mId.hashCode();
    }

    public void setId(ObjectId id)
    {
        mId = id;
    }

    public ObjectId getId()
    {
        return mId;
    }

    public String getName()
    {
        return mName;
    }

    public void setName(String name)
    {
        this.mName = name;
    }

    public String getComment()
    {
        return mComment;
    }

    public void setComment(String comment)
    {
        this.mComment = comment;
    }

    public boolean isEditable()
    {
        return isEditable;
    }

    public void setEditable(boolean editable)
    {
        isEditable = editable;
    }

    public void setDate(Date date)
    {
        mDate = date;
    }

    public String dateToString()
    {
        if (mDate != null)
        {
            return mSimpleDateFormat.format(mDate);
        }
        else
        {
            Log.w(TAG, "dateToString: date is null!");
            return null;
        }
    }

    public int getRate()
    {
        return mRate;
    }

    public void setRate(int rate)
    {
        mRate = rate;
    }
}
