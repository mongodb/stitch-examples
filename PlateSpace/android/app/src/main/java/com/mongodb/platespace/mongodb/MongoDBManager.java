package com.mongodb.platespace.mongodb;

import android.content.Context;
import android.support.annotation.NonNull;
import android.support.annotation.Nullable;
import android.util.Log;

import com.facebook.Profile;
import com.facebook.ProfileTracker;
import com.facebook.login.LoginManager;
import com.google.android.gms.tasks.Continuation;
import com.google.android.gms.tasks.OnCompleteListener;
import com.google.android.gms.tasks.Task;
import com.mongodb.platespace.interfaces.QueryListener;
import com.mongodb.platespace.model.Attributes;
import com.mongodb.platespace.model.Restaurant;
import com.mongodb.platespace.model.Review;
import com.mongodb.stitch.android.PipelineStage;
import com.mongodb.stitch.android.StitchClient;
import com.mongodb.stitch.android.auth.Auth;
import com.mongodb.stitch.android.auth.AvailableAuthProviders;
import com.mongodb.stitch.android.auth.anonymous.AnonymousAuthProvider;
import com.mongodb.stitch.android.auth.anonymous.AnonymousAuthProviderInfo;
import com.mongodb.stitch.android.auth.oauth2.facebook.FacebookAuthProvider;
import com.mongodb.stitch.android.services.mongodb.MongoClient;

import org.bson.Document;
import org.bson.types.ObjectId;

import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.Map;


/**
 * Helper class to control all communication with MongoDB in one place.
 * For this sample app we chose to use it as a singleton class
 */

public class MongoDBManager
{
    private static final String TAG = MongoDBManager.class.getSimpleName();

    private static MongoDBManager ourInstance;


    private StitchClient mStitchClient;
    private MongoClient mMongoDBClient;

    private String mUserName;

    /*
    * Helper class to keep all the statics
    * */
    private class Statics
    {
        private static final String DB_NAME = "YOUR_DB_NAME";
        private static final String APP_ID = "YOUR_APP_ID";
        private static final String SERVICE_NAME = "YOUR_SERVICE_NAME";
    }

    /*
     * Helper class to keep the names of the database collections in one place
     */
    private class DBCollections
    {
        private static final String RESTAURANTS = "restaurants";
        private static final String REVIEWS_RATINGS = "reviewsRatings";
    }


    public synchronized static MongoDBManager getInstance(Context context)
    {
        if (ourInstance == null)
        {
            ourInstance = new MongoDBManager(context);
        }

        return ourInstance;
    }

    private MongoDBManager(Context context)
    {
        //initialize the Stitch client and the MongoClient

        mStitchClient = new StitchClient(context, Statics.APP_ID);
        mMongoDBClient = new MongoClient(mStitchClient, Statics.SERVICE_NAME);


        //try to get the user name if we are connected to Facebook
        Profile facebookProfile = Profile.getCurrentProfile();
        if (facebookProfile != null)
        {
            mUserName = facebookProfile.getName();
        }
    }

    /*
    Helper method to reduce the boilerplate code
    * */
    private MongoClient.Database getDatabase()
    {
        return mMongoDBClient.getDatabase(Statics.DB_NAME);
    }

    /**
     * @return the id of the user that is connected to the Stitch client
     */
    public String getUserId()
    {
        return mStitchClient.getAuth().getUserId();
    }


    /**
     * @return true if user signed in to app as anonymous, false otherwise
     */
    public boolean isAnonymous()
    {
        Auth auth = mStitchClient.getAuth();
        String provider = auth != null ? auth.getProvider() : null;


        //check if we used the AnonymousAuthProvider when logging in
        return AnonymousAuthProviderInfo.FQ_NAME.equals(provider);
    }

    public boolean isConnected()
    {
        return mStitchClient.isAuthenticated();
    }

    public void doAnonymousAuthentication(final QueryListener<Void> loginListener)
    {
        /*
        Log in anonymously.

        1. get authentication providers to know if anonymous authentication is enabled by the service.
        2. if anonymous authentication is enabled, try to login
        * */
        mStitchClient.getAuthProviders().addOnCompleteListener(new OnCompleteListener<AvailableAuthProviders>()
        {
            @Override
            public void onComplete(@NonNull final Task<AvailableAuthProviders> task)
            {
                if (!task.isSuccessful())
                {
                    Log.e(TAG, "Could not retrieve authentication providers");
                    if (loginListener != null)
                    {
                        loginListener.onError(task.getException());
                    }
                }
                else
                {
                    Log.i(TAG, "Retrieved authentication providers");
                    mUserName = null;
                    if (task.getResult().hasAnonymous())
                    {

                        /*
                        * Service enabled anonymous authentication
                        * */

                        //login anonymously
                        mStitchClient.logInWithProvider(new AnonymousAuthProvider()).continueWith(new Continuation<Auth, Object>()
                        {
                            @Override
                            public Object then(@NonNull final Task<Auth> task) throws Exception
                            {
                                if (task.isSuccessful())
                                {
                                    //we are logged in anonymously

                                    Log.i(TAG, "User Authenticated as " + mStitchClient.getAuth().getUserId());
                                    if (loginListener != null)
                                    {
                                        loginListener.onSuccess(null);
                                    }
                                }
                                else
                                {
                                    //failed

                                    String msg = "Error logging in anonymously";
                                    Log.e(TAG, msg, task.getException());
                                    if (loginListener != null)
                                    {
                                        loginListener.onError(task.getException());
                                    }
                                }
                                return null;
                            }
                        });
                    }
                    else
                    {
                        //the service doesn't allow anonymous authentication

                        if (loginListener != null)
                        {
                            loginListener.onError(new Exception("Anonymous not supported"));
                        }
                    }
                }
            }
        });
    }

    public void doFacebookAuthentication(final String accessToken, final QueryListener<Void> listener)
    {
        /*
        Log in with Facebook.

        1. get authentication providers to know if Facebook authentication is enabled by the service.
        2. if Facebook authentication is enabled, try to login
        * */
        mStitchClient.getAuthProviders().addOnCompleteListener(new OnCompleteListener<AvailableAuthProviders>()
        {
            @Override
            public void onComplete(@NonNull final Task<AvailableAuthProviders> task)
            {
                if (!task.isSuccessful())
                {
                    Log.e(TAG, "Could not retrieve authentication providers");
                    if (listener != null)
                    {
                        listener.onError(task.getException());
                    }
                }
                else
                {
                    Log.i(TAG, "Retrieved authentication providers");

                    if (task.getResult().hasFacebook())
                    {

                        /*
                        * Facebook authentication is enabled by the service,
                        * try to login using the access token we got from Facebook SDK
                        * */
                        mStitchClient.logInWithProvider(FacebookAuthProvider.fromAccessToken(accessToken)).continueWith(new Continuation<Auth, Object>()
                        {
                            private ProfileTracker mProfileTracker;

                            @Override
                            public Object then(@NonNull final Task<Auth> task) throws Exception
                            {
                                if (task.isSuccessful())
                                {
                                    //we are logged in with Facebook

                                    Log.i(TAG, "User Authenticated as " + mStitchClient.getAuth().getUserId());

                                    //try to get the user name from Facebook SDK
                                    if (Profile.getCurrentProfile() == null)
                                    {
                                        mProfileTracker = new ProfileTracker()
                                        {
                                            @Override
                                            protected void onCurrentProfileChanged(Profile oldProfile, Profile currentProfile)
                                            {
                                                mUserName = currentProfile.getName();
                                                mProfileTracker.stopTracking();
                                            }
                                        };
                                    }
                                    else
                                    {
                                        mUserName = Profile.getCurrentProfile().getName();
                                    }


                                    if (listener != null)
                                    {
                                        listener.onSuccess(null);
                                    }
                                }
                                else
                                {
                                    String msg = "Error logging with facebook";
                                    Log.e(TAG, msg, task.getException());
                                    if (listener != null)
                                    {
                                        listener.onError(task.getException());
                                    }

                                }
                                return null;
                            }
                        });
                    }
                    else
                    {
                        /*
                        * The service does not support Facebook authentication
                        * */
                        listener.onError(new Exception("Facebook not supported"));
                    }
                }
            }
        });
    }


    /*
    * Logout from MongoDB & Facebook SDK
    * */
    public void logout(final QueryListener<Void> listener)
    {
        LoginManager.getInstance().logOut(); //logout from Facebook
        mUserName = null;

        //logout from MongoDB
        mStitchClient.logout().continueWith(new Continuation<Void, Object>()
        {
            @Override
            public Object then(@NonNull Task<Void> task) throws Exception
            {
                if (task.isSuccessful())
                {
                    Log.d(TAG, "then: logged out");
                    if (listener != null)
                    {
                        listener.onSuccess(null);
                    }
                }
                else
                {
                    if (listener != null)
                    {
                        listener.onError(task.getException());
                    }
                }
                return null;
            }
        });
    }

    @SuppressWarnings("unchecked")
    public void geoNear(@Nullable String keyword, @Nullable final Attributes filters,
                        double latitude, double longitude, @Nullable Restaurant farthestRestaurant, int limit, final QueryListener<List<Restaurant>> listener)
    {

        /*
        * Get a list of restaurant, sorted by descending distance from a current location.
        *
        * The list has a limit, attributed, and possibly a keyword
        * */


        Document query = new Document();


        if (filters != null)
        {
            /*
            * The user wants to include filter attributes in his search.
            * Since the attributed are an inner class of a restaurant, we need to use the dot notation
            * https://docs.mongodb.com/manual/core/document/
            **/

            if (filters.isVeganFriendly())
            {
                query.put(Restaurant.Field.ATTRIBUTES + "." + Attributes.Field.VEGAN_FRIENDLY, true);
            }

            if (filters.isOpenOnWeekends())
            {
                query.put(Restaurant.Field.ATTRIBUTES + "." + Attributes.Field.OPEN_ON_WEEKENDS, true);
            }

            if (filters.hasParking())
            {
                query.put(Restaurant.Field.ATTRIBUTES + "." + Attributes.Field.HAS_PARKING, true);
            }

            if (filters.hasWifi())
            {
                query.put(Restaurant.Field.ATTRIBUTES + "." + Attributes.Field.HAS_WIFI, true);
            }
        }


        if (keyword != null)
        {
            /*
            User searches for similar restaurant names.
            * We implement this search using the $regex operator, with case insensitivity to match upper and lower cases.
            *
            *
            * https://docs.mongodb.com/manual/reference/operator/query/regex/
            * */
            query.put(Restaurant.Field.NAME, new Document("$regex", keyword).append("$options", "i"));
        }

        if (farthestRestaurant != null)
        {
            /*
            * We already have the farthest restaurant, so we don't wanna get it the next iteration.
            * Therefor, get the restaurants which id != farthestRestaurant
            * */

            query.put(Restaurant.Field.ID, new Document("$ne", farthestRestaurant.getId()));
        }

        List<Document> items = new ArrayList<>();
        items.add(new Document("result", "%%vars.geo_matches")); //bind the arguments to our named pipeline required parameters


        /*
        The pagination is implemented in the following way:

        * 1. to get the first page, we sort the distances with a minimum distance of 0.
        * This will return the closest restaurant first, and the farthest last (according to our geoNear named pipeline).
        *
        * 2. Once we finished step 1, we keep the distance of the farthest restaurant (i.e 1000 meters).
        * For the next page will will set the min distance to the farthest distance, so that the results received will only have
        * a distance >= farthest restaurant (I.e, the second stage will return restaurants with a minimum distance of 1000 meters).
        *
        * Note: make sure to exclude the farthest restaurant so we don't have duplicates (once in stage 1, and second time in stage 2)
        *
        * 3. Keep iterating over step 2 until the result list size is smaller than the limit given.
        * That means there is no more data.
        *
        * */

        double minDistance = farthestRestaurant == null ? 0 : farthestRestaurant.getDistance();


        Document argsMap = new Document()
                .append("latitude", latitude) //the current phone latitude
                .append("longitude", longitude) //the current phone longitude
                .append("query", query) //query will contain any additional parameters
                .append("minDistance", minDistance) //pagination parameter
                .append("limit", limit); //pagination limit


        Document pipelineMap = new Document()
                .append("name", "geoNear") //our named pipeline in the service
                .append("args", argsMap); //required parameters for the named pipeline


        /*
        * To execute the named pipeline we need to use the pipeline stage
        *
        * (**** INSERT LINK TO NAMED PIPELINE DOCUMENTATION HERE *****)
        * */
        PipelineStage literalStage = new PipelineStage("literal", new Document("items", items),
                new Document("geo_matches", new Document("%pipeline", pipelineMap)));

        mStitchClient.executePipeline(literalStage).continueWith(new Continuation<List<Object>, Object>()
        {
            @Override
            public Object then(@NonNull Task<List<Object>> task) throws Exception
            {
                if (task.isSuccessful())
                {
                    Log.d(TAG, "then isSuccessful: ");

                    List<Restaurant> list = new ArrayList<>();
                    Map<String, Object> map = (Map<String, Object>) task.getResult().get(0);


                    //get the list of results from the query
                    List<Object> resultList = (List<Object>) map.get("result");
                    for (Object object : resultList)
                    {
                        //parse document object to a Restaurant model object
                        list.add(Restaurant.fromDocument((Document) object));
                    }

                    if (listener != null)
                    {
                        listener.onSuccess(list);
                    }
                }
                else
                {
                    Log.e(TAG, "then: ", task.getException());
                    if (listener != null)
                    {
                        listener.onError(task.getException());
                    }

                }

                return null;
            }
        });

    }

    public void refreshRestaurant(final Restaurant restaurant, final QueryListener<Restaurant> listener)
    {
        /*
        * Find a specific restaurant within the DB (using the unique restaurant id).
        * */

        Document query = new Document(Restaurant.Field.ID, restaurant.getId());
        getDatabase().getCollection(DBCollections.RESTAURANTS).find(query).continueWith(new Continuation<List<Document>, Object>()
        {
            @Override
            public Object then(@NonNull Task<List<Document>> task) throws Exception
            {
                if (task.isSuccessful())
                {
                    List<Document> result = task.getResult();

                    //we know each restaurant has its own unique id, so we consider an empty list as an error.
                    if (result.isEmpty())
                    {
                        if (listener != null)
                        {
                            listener.onError(new Exception("Unable to refresh restaurant"));
                        }
                    }
                    else
                    {
                        Restaurant refreshedRestaurant = Restaurant.fromDocument(result.get(0));
                        if (listener != null)
                        {
                            listener.onSuccess(refreshedRestaurant);
                        }
                    }
                }
                else
                {
                    if (listener != null)
                    {
                        listener.onError(task.getException());
                    }
                }
                return null;
            }
        });
    }

    @SuppressWarnings("unchecked")
    public void updateRatings(final Restaurant restaurant, final QueryListener<Void> listener)
    {

        /*
        This named pipeline defined in the service goes over every
        rating that is attached to a certain restaurant, collects the average rating and updates it
        in the specific restaurant
        */

        List<Document> items = new ArrayList<>();
        items.add(new Document("result", "%%vars.updateRatings"));


        Document pipelineMap = new Document()
                .append("name", "updateRatings") //our named pipeline
                .append("args", new Document("restaurantId", restaurant.getId())); //the arguments for our named pipeline


        PipelineStage literalStage = new PipelineStage("literal",
                new Document("items", items),
                new Document("updateRatings", new Document("%pipeline", pipelineMap)));

        mStitchClient.executePipeline(literalStage).continueWith(new Continuation<List<Object>, Object>()
        {
            @Override
            public Object then(@NonNull Task<List<Object>> task) throws Exception
            {
                if (task.isSuccessful())
                {
                    /*
                    * In our named pipeline, we return 'false' or 'true' to know if the query was a success
                    * */

                    Log.d(TAG, "then: isSuccessful");
                    Map<String, Object> result = (Map<String, Object>) task.getResult().get(0);
                    boolean boolResult = (boolean) result.get("result");

                    if (listener != null)
                    {
                        if (boolResult)
                        {
                            listener.onSuccess(null);
                        }
                        else
                        {
                            listener.onError(new Exception("Update failed"));
                        }
                    }
                }
                else
                {
                    Log.e(TAG, "then: ", task.getException());
                    if (listener != null)
                    {
                        listener.onError(task.getException());
                    }
                }
                return null;
            }
        });
    }

    public void getRestaurantReviews(final Restaurant restaurant, final QueryListener<List<Review>> listener)
    {
        /*
        * Get the reviews of a restaurant, except for the review of the user that is logged in.
        * */

        Document matchQuery = new Document()
                .append(Review.Field.RESTAURANT_ID, restaurant.getId())
                .append(Review.Field.OWNER_ID, new Document("$ne", getUserId()));

        List<Document> pipeline = new ArrayList<>();
        pipeline.add(new Document("$match", matchQuery));
        pipeline.add(new Document("$sort", new Document(Review.Field.DATE, -1)));


        Document args = new Document();
        args.put("database", Statics.DB_NAME);
        args.put("collection", DBCollections.REVIEWS_RATINGS);
        args.put("pipeline", pipeline);


        mStitchClient.executePipeline(new PipelineStage("aggregate", Statics.SERVICE_NAME, args)).continueWith(new Continuation<List<Object>, Object>()
        {
            @Override
            public Object then(@NonNull Task<List<Object>> task) throws Exception
            {
                if (!task.isSuccessful())
                {
                    Log.e(TAG, "Failed to execute query");
                    if (listener != null)
                    {
                        listener.onError(task.getException());
                    }
                }
                else
                {

                    List<Review> list = new ArrayList<>();
                    List<Object> result = task.getResult();
                    if (result == null || result.isEmpty())
                    {
                        Log.d(TAG, "No results found");
                    }
                    else
                    {
                        for (Object object : result)
                        {
                            //parse the Review model object from the result
                            list.add(Review.fromDocument((Document) object));
                        }
                    }

                    if (listener != null)
                    {
                        listener.onSuccess(list);
                    }
                }

                return null;
            }
        });
    }

    public void getOwnerRestaurantReview(final Restaurant restaurant, final QueryListener<Review> listener)
    {

        /*
        * Get the restaurant review of the user that is currently logged in to the app
        * */

        Document query = new Document()
                .append(Review.Field.RESTAURANT_ID, restaurant.getId())
                .append(Review.Field.OWNER_ID, getUserId());


        getDatabase().getCollection(DBCollections.REVIEWS_RATINGS).find(query).continueWith(new Continuation<List<Document>, Object>()
        {
            @Override
            public Object then(@NonNull final Task<List<Document>> task) throws Exception
            {
                if (!task.isSuccessful())
                {
                    Log.e(TAG, "Failed to execute query");
                    if (listener != null)
                    {
                        listener.onError(task.getException());
                    }
                }
                else
                {
                    Review review = null;
                    List<Document> result = task.getResult();
                    if (result == null || result.isEmpty())
                    {
                        Log.d(TAG, "No results found");
                    }
                    else
                    {
                        //there should only be 1 review per user
                        review = Review.fromDocument(result.get(0));

                        //since it's the review of the logged in user, we mark the review editable
                        review.setEditable(true);
                    }

                    if (listener != null)
                    {
                        listener.onSuccess(review);
                    }
                }

                return null;
            }
        });
    }

    public void addReview(@NonNull final String comment, final int rate, @NonNull final Restaurant restaurant, final QueryListener<Review> listener)
    {
        /*
        * Add a new review for a specific restaurant
        *
        * */

        /*
        We init the object id so that we already have it when the query finishes.
        If we didn't initialize it here, it would have been initialize automatically
         */
        final ObjectId id = new ObjectId();
        final Date date = new Date();

        Document query = new Document(Review.Field.ID, id)
                .append(Review.Field.COMMENT, comment)
                .append(Review.Field.RESTAURANT_ID, restaurant.getId())
                .append(Review.Field.OWNER_ID, getUserId())
                .append(Review.Field.DATE, date)
                .append(Review.Field.NAME_OF_REVIEWER, mUserName);


        //for this app we only allow ratings that are > 0
        if (rate > 0)
        {
            query.append(Review.Field.RATE, rate);
        }

        getDatabase().getCollection(DBCollections.REVIEWS_RATINGS).insertOne(query).continueWith(new Continuation<Void, Object>()
        {
            @Override
            public Object then(@NonNull Task<Void> task) throws Exception
            {
                if (!task.isSuccessful())
                {
                    Log.e(TAG, "Failed to execute query");
                    if (listener != null)
                    {
                        listener.onError(task.getException());
                    }
                }
                else
                {
                    //construct the newly added review
                    if (listener != null)
                    {
                        Review review = new Review();
                        review.setId(id);
                        review.setComment(comment);
                        review.setName(mUserName);
                        review.setRate(rate);
                        review.setDate(date);
                        review.setEditable(true);
                        listener.onSuccess(review);
                    }
                }

                return null;
            }
        });

    }

    public void editReview(@NonNull final String newComment, final int rate, @NonNull final Review previousReview, final QueryListener<Review> listener)
    {

        /*
        * Edit an existing review
        * */

        //we get the existing review by its id
        Document query = new Document(Review.Field.ID, previousReview.getId());

        Document setDocument = new Document(Review.Field.COMMENT, newComment);
        if (rate > 0)
        {
            //only allow ratings that are bigger than 0
            setDocument.append(Review.Field.RATE, rate);
        }

        getDatabase().getCollection(DBCollections.REVIEWS_RATINGS).updateOne(query, new Document("$set", setDocument)).continueWith(new Continuation<Void, Object>()
        {
            @Override
            public Object then(@NonNull Task<Void> task) throws Exception
            {
                if (!task.isSuccessful())
                {
                    Log.e(TAG, "Failed to execute query");
                    if (listener != null)
                    {
                        listener.onError(task.getException());
                    }
                }
                else
                {
                    //edit the previous review
                    previousReview.setComment(newComment);
                    previousReview.setRate(rate);
                    previousReview.setEditable(true);
                    if (listener != null)
                    {
                        listener.onSuccess(previousReview);
                    }
                }

                return null;
            }
        });
    }
}
