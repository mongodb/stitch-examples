package com.mongodb.platespace.activities;

import android.annotation.SuppressLint;
import android.app.Dialog;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.graphics.PorterDuff;
import android.os.Bundle;
import android.support.annotation.NonNull;
import android.support.annotation.Nullable;
import android.support.v4.content.ContextCompat;
import android.support.v7.app.AlertDialog;
import android.support.v7.widget.LinearLayoutManager;
import android.support.v7.widget.RecyclerView;
import android.support.v7.widget.Toolbar;
import android.text.Editable;
import android.text.TextUtils;
import android.text.TextWatcher;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.MenuItem;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ImageButton;
import android.widget.ImageView;
import android.widget.TextView;
import android.widget.Toast;

import com.bumptech.glide.Glide;
import com.iarcuschin.simpleratingbar.SimpleRatingBar;
import com.mongodb.platespace.R;
import com.mongodb.platespace.interfaces.QueryListener;
import com.mongodb.platespace.model.Restaurant;
import com.mongodb.platespace.model.Review;
import com.mongodb.platespace.mongodb.MongoDBManager;
import com.mongodb.platespace.utils.ProgressDialog;

import java.util.LinkedList;
import java.util.List;
import java.util.Locale;

import static android.view.View.GONE;


/**
 * Show the page of a restaurant
 */

public class RestaurantActivity extends LoggedInActivity
{
    private static final String LOG_TAG = RestaurantActivity.class.getSimpleName();
    public static final String KEY_RESTAURANT = "KEY_RESTAURANT";


    private ReviewAdapter mAdapter;
    private Restaurant mRestaurant;
    private Review mOwnerReview;

    private int mCurrentRate;

    public static Intent newIntent(Context context, Restaurant restaurant)
    {
        Intent intent = new Intent(context, RestaurantActivity.class);
        intent.putExtra(KEY_RESTAURANT, restaurant);
        return intent;
    }

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState)
    {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_restaurant);
        Toolbar myToolbar = (Toolbar) findViewById(R.id.my_toolbar);
        setSupportActionBar(myToolbar);
        if (getSupportActionBar() != null)
        {
            getSupportActionBar().setDisplayHomeAsUpEnabled(true);
        }

        if (getIntent() != null && getIntent().getExtras() != null)
        {
            //get the restaurant from the previous activity
            mRestaurant = getIntent().getExtras().getParcelable(KEY_RESTAURANT);
        }

        initRecyclerView();
        initRestaurantReviews();
    }

    private void initRestaurantReviews()
    {
        mAdapter.clear();
        mAdapter.notifyDataSetChanged();

        //get the reviews of the restaurant (not including the review of the logged in user)
        MongoDBManager.getInstance(getApplicationContext()).getRestaurantReviews(mRestaurant, new QueryListener<List<Review>>()
        {
            @Override
            public void onSuccess(List<Review> reviews)
            {
                mAdapter.addReviews(reviews);
                mAdapter.notifyDataSetChanged();
            }

            @Override
            public void onError(Exception e)
            {
                Log.e(LOG_TAG, "onError: failed getting restaurant reviews", e);
            }
        });

        //get the review of the logged in user
        MongoDBManager.getInstance(getApplicationContext()).getOwnerRestaurantReview(mRestaurant, new QueryListener<Review>()
        {
            @Override
            public void onSuccess(Review review)
            {
                Log.d(LOG_TAG, "onSuccess: got owner restaurant reviews");
                if (review != null)
                {
                    //we keep the owner review in case we want to edit it.
                    mOwnerReview = review;

                    //only add the review if it has a comment
                    if (!TextUtils.isEmpty(mOwnerReview.getComment()))
                    {
                        mAdapter.addUserReview(review);
                    }

                    mAdapter.notifyDataSetChanged();
                }
            }

            @Override
            public void onError(Exception e)
            {
                Log.d(LOG_TAG, "onError: failed getting restaurant reviews");
            }
        });
    }

    private boolean isAnonymous()
    {
        //tell us if the user logged in anonymously or not.
        return MongoDBManager.getInstance(getApplicationContext()).isAnonymous();
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item)
    {
        switch (item.getItemId())
        {
            case android.R.id.home:
                onBackPressed();
                return true;
        }

        return super.onOptionsItemSelected(item);
    }

    @Override
    public void onBackPressed()
    {
        onBack();
    }

    private void onBack()
    {
        setResult(RESULT_OK, MainActivity.fromRestaurantActivity(mRestaurant));
        finish();
    }

    @Override
    protected void onResume()
    {
        super.onResume();

        //refresh restaurant when coming back from background
        refreshRestaurant();
    }

    private void initRecyclerView()
    {
        RecyclerView recyclerView = (RecyclerView) findViewById(R.id.review_recycler_view);

        LinearLayoutManager layoutManager = new LinearLayoutManager(this);
        recyclerView.setHasFixedSize(true);
        recyclerView.setLayoutManager(layoutManager);
        mAdapter = new ReviewAdapter();
        recyclerView.setAdapter(mAdapter);
    }

    @SuppressLint("InflateParams")
    private void addReviewDialog()
    {
        //show a dialog to add a review
        final View v = LayoutInflater.from(this).inflate(R.layout.dialog_input, null, false);
        final EditText input = (EditText) v.findViewById(R.id.dialog_input);
        AlertDialog.Builder builder = new AlertDialog.Builder(this, R.style.DialogTheme);
        builder.setTitle(R.string.add_review)
                .setView(v)
                .setCancelable(false)
                .setNegativeButton(R.string.cancel, new DialogInterface.OnClickListener()
                {
                    @Override
                    public void onClick(DialogInterface dialog, int which)
                    {
                        dialog.dismiss();
                    }
                })
                .setPositiveButton(R.string.add, new DialogInterface.OnClickListener()
                {
                    @Override
                    public void onClick(DialogInterface dialog, int which)
                    {
                        //add a new review, or edit an existing review
                        addOrEditReview(input.getText().toString());
                    }
                });

        final AlertDialog dialog = builder.show();
        final Button addReviewButton = dialog.getButton(AlertDialog.BUTTON_POSITIVE);
        setDialogButtonEnabled(addReviewButton, false);

        //bug fix - in Meizu M1 Note (Android 5.1, API 22) the editText underline does not get the color accent from the app
        input.getBackground().setColorFilter(ContextCompat.getColor(this, R.color.colorAccent), PorterDuff.Mode.SRC_IN);
        input.addTextChangedListener(new TextWatcher()
        {
            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after)
            {

            }

            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count)
            {
                //I don't want to enable empty comments
                setDialogButtonEnabled(addReviewButton, !TextUtils.isEmpty(s.toString().trim()));
            }

            @Override
            public void afterTextChanged(Editable s)
            {

            }
        });
    }

    @SuppressLint("InflateParams")
    private void editReviewDialog(String review)
    {
        //show a dialog to edit an existing review
        final View v = LayoutInflater.from(this).inflate(R.layout.dialog_input, null, false);
        final EditText input = (EditText) v.findViewById(R.id.dialog_input);
        input.setText(review);


        AlertDialog.Builder builder = new AlertDialog.Builder(this, R.style.DialogTheme);
        builder.setTitle(R.string.edit_review)
                .setView(v)
                .setCancelable(false)
                .setNegativeButton(R.string.cancel, new DialogInterface.OnClickListener()
                {
                    @Override
                    public void onClick(DialogInterface dialog, int which)
                    {
                        dialog.dismiss();
                    }
                })
                .setPositiveButton(R.string.edit, new DialogInterface.OnClickListener()
                {
                    @Override
                    public void onClick(DialogInterface dialog, int which)
                    {
                        Log.d(LOG_TAG, "onClick: review text: " + input.getText().toString());
                        addOrEditReview(input.getText().toString());
                    }
                });

        final AlertDialog dialog = builder.show();
        final Button addReviewButton = dialog.getButton(AlertDialog.BUTTON_POSITIVE);
        setDialogButtonEnabled(addReviewButton, !TextUtils.isEmpty(review.trim()));

        //bug fix - in Meizu M1 Note (Android 5.1, API 22) the editText underline does not get the color accent from the app
        input.getBackground().setColorFilter(ContextCompat.getColor(this, R.color.colorAccent), PorterDuff.Mode.SRC_IN);
        input.addTextChangedListener(new TextWatcher()
        {
            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after)
            {

            }

            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count)
            {
                //I don't want to enable empty comments
                setDialogButtonEnabled(addReviewButton, !TextUtils.isEmpty(s.toString().trim()));
            }

            @Override
            public void afterTextChanged(Editable s)
            {

            }
        });
    }

    private void setDialogButtonEnabled(@NonNull Button btn, boolean enabled)
    {
        if (enabled)
        {
            btn.setEnabled(true);
            btn.setTextColor(ContextCompat.getColor(RestaurantActivity.this, R.color.colorAccent));
        }
        else
        {
            btn.setEnabled(false);
            btn.setTextColor(ContextCompat.getColor(RestaurantActivity.this, R.color.colorAccent_50_alpha));
        }
    }

    private void addOrEditReview(String review)
    {
        final Dialog progressDialog = ProgressDialog.getDialog(this, true);
        progressDialog.show();

        //in this case, the same listener is used regardless if we're editing a review or adding a new one
        QueryListener<Review> queryListener = new QueryListener<Review>()
        {
            @Override
            public void onSuccess(Review result)
            {
                progressDialog.dismiss();

                //update the owner review
                mOwnerReview = result;
                mAdapter.addUserReview(mOwnerReview);
                mAdapter.notifyDataSetChanged();
            }

            @Override
            public void onError(Exception e)
            {
                progressDialog.dismiss();
                Log.e(LOG_TAG, "onError: ", e);
                Toast.makeText(getApplicationContext(), R.string.review_error, Toast.LENGTH_LONG).show();
            }
        };

        String trimmedReview = trimText(review);

        if (mOwnerReview == null)
        {
            //A previous review doesn't exist. Add a new review
            MongoDBManager.getInstance(getApplicationContext()).addReview(trimmedReview, mCurrentRate, mRestaurant, queryListener);
        }
        else
        {
            //A previous review exists. Edit it.
            MongoDBManager.getInstance(getApplicationContext()).editReview(trimmedReview, mCurrentRate, mOwnerReview, queryListener);
        }

    }

    private void openMap()
    {
        //show the restaurant in the map activity
        startActivity(MapActivity.newIntent(this, mRestaurant));
    }

    private void rateRestaurant()
    {
        Log.d(LOG_TAG, "rateRestaurant: rating " + mCurrentRate);
        final Dialog progressDialog = ProgressDialog.getDialog(this, true);
        progressDialog.show();
        QueryListener<Review> queryListener = new QueryListener<Review>()
        {
            @Override
            public void onSuccess(Review result)
            {
                Log.d(LOG_TAG, "onSuccess: rating the restaurant successful");
                progressDialog.dismiss();

                //update the owner review
                mOwnerReview = result;
                mAdapter.notifyDataSetChanged();

                /*
                * The rating was changed.
                * Make a call to update the average rating of the restaurant as a result of the change
                * */
                updateRatings();
            }

            @Override
            public void onError(Exception e)
            {
                progressDialog.dismiss();
                Log.e(LOG_TAG, "onError: ", e);
                Toast.makeText(getApplicationContext(), R.string.review_error, Toast.LENGTH_LONG).show();
            }

        };


        if (mOwnerReview == null)
        {
            //add new rating
            MongoDBManager.getInstance(getApplicationContext()).addReview("", mCurrentRate, mRestaurant, queryListener);
        }
        else
        {
            //edit existing rating
            MongoDBManager.getInstance(getApplicationContext()).editReview(trimText(mOwnerReview.getComment()), mCurrentRate, mOwnerReview, queryListener);
        }
    }

    private void updateRatings()
    {
        MongoDBManager.getInstance(getApplicationContext()).updateRatings(mRestaurant, new QueryListener<Void>()
        {
            @Override
            public void onSuccess(Void result)
            {
                Log.d(LOG_TAG, "onSuccess: ");

                /*The average rating of the restaurant could be changed now in the DB,
                * so we need to get the updated restaurant
                * */
                refreshRestaurant();
            }

            @Override
            public void onError(Exception e)
            {
                Log.e(LOG_TAG, "onError: ", e);
            }
        });
    }

    private void refreshRestaurant()
    {
        //refresh the existing restaurant fro the DB
        MongoDBManager.getInstance(getApplicationContext()).refreshRestaurant(mRestaurant, new QueryListener<Restaurant>()
        {
            @Override
            public void onSuccess(Restaurant result)
            {
                Log.d(LOG_TAG, "onSuccess: refreshed restaurant");
                mRestaurant = result;
                mAdapter.notifyDataSetChanged();
            }

            @Override
            public void onError(Exception e)
            {
                Log.e(LOG_TAG, "onError: ", e);
            }
        });
    }

    private void showRatingDisabledDialog()
    {
        /*
        A user can only rate a restaurant if he's not logged in anonymously
        */
        AlertDialog.Builder builder = new AlertDialog.Builder(this, R.style.DialogTheme);
        builder.setTitle(R.string.rating_disabled_dialog_title)
                .setMessage(R.string.rating_disabled_dialog_msg)
                .setPositiveButton(R.string.ok, new DialogInterface.OnClickListener()
                {
                    @Override
                    public void onClick(DialogInterface dialog, int which)
                    {
                        dialog.dismiss();
                    }
                }).show();
    }

    private String trimText(@NonNull String text)
    {
        try
        {
            return text.trim().replaceAll(System.lineSeparator(), " ").replaceAll(" +", " ");
        }
        catch (Exception e)
        {
            return text;
        }
    }

    private boolean isAddReviewEnabled()
    {
        /*
        * You can only add a new review if you are not logged in anonymously, and you don't have a previous review.
        * Otherwise, you can edit the existing review
        * */

        return !isAnonymous() && (mOwnerReview == null || TextUtils.isEmpty(mOwnerReview.getComment()));
    }

    private View.OnClickListener mAddReviewListener = new View.OnClickListener()
    {
        @Override
        public void onClick(View v)
        {
            addReviewDialog();
        }
    };

    private class ReviewAdapter extends RecyclerView.Adapter<RecyclerView.ViewHolder>
    {
        private static final int TYPE_HEADER = 0;
        private static final int TYPE_ITEM = 1;
        private static final int TYPE_EMPTY = 2;

        private List<Review> mDataSet = new LinkedList<>();

        void addReviews(List<Review> userReviews)
        {
            mDataSet.addAll(userReviews);
        }

        void addUserReview(Review userReview)
        {
            /*
            the owner review should show first
            * */
            if (mDataSet.contains(userReview))
            {
                mDataSet.remove(userReview);
            }

            mDataSet.add(0, userReview);
        }

        void clear()
        {
            mDataSet.clear();
        }

        @Override
        public RecyclerView.ViewHolder onCreateViewHolder(ViewGroup parent, int viewType)
        {
            if (viewType == TYPE_HEADER)
            {
                View root = LayoutInflater.from(parent.getContext()).inflate(R.layout.header_review, parent, false);
                return new ViewHolderHeader(root);
            }
            else if (viewType == TYPE_ITEM)
            {
                View root = LayoutInflater.from(parent.getContext()).inflate(R.layout.list_item_review, parent, false);
                return new ViewHolderItem(root);
            }
            else if (viewType == TYPE_EMPTY)
            {
                View root = LayoutInflater.from(parent.getContext()).inflate(R.layout.empty_view, parent, false);
                return new EmptyViewHolder(root);
            }

            throw new RuntimeException("There is no type that matches the type " + viewType);
        }

        @Override
        public void onBindViewHolder(RecyclerView.ViewHolder holder, int position)
        {
            /*
            Bind the restaurant data to the UI
            * */

            if (holder instanceof ViewHolderHeader)
            {
                final ViewHolderHeader vh = (ViewHolderHeader) holder;
                Glide.with(RestaurantActivity.this).load(mRestaurant.getImageUrl()).placeholder(R.drawable.rest_placeholder)
                        .centerCrop().into(vh.mBackgroundImage);
                vh.mAddReview.setEnabled(isAddReviewEnabled());
                vh.mAddReview.setOnClickListener(mAddReviewListener);
                vh.mName.setText(mRestaurant.getName());
                vh.mOpeningTimes.setText(mRestaurant.getOpeningHours().isOpen() ? R.string.open_now : R.string.closed_now);
                vh.mMap.setOnClickListener(new View.OnClickListener()
                {
                    @Override
                    public void onClick(View v)
                    {
                        openMap();
                    }
                });
                vh.mAverageRatingText.setText(formatDecimal(mRestaurant.getAverageRating()));
                vh.mAverageRating.setRating((float) mRestaurant.getAverageRating());
                int reviewsCount = (int) mRestaurant.getNumberOfRates();
                vh.mRatingsNumber.setText(getResources().getQuantityString(R.plurals.ratings_number, reviewsCount, reviewsCount));
                vh.mAddress.setText(getAddressString(mRestaurant.getAddress()));
                vh.mWebsite.setText(mRestaurant.getWebsite());
                vh.mPhone.setText(mRestaurant.getPhone());
                vh.mRateNow.setOnRatingBarChangeListener(new SimpleRatingBar.OnRatingBarChangeListener()
                {
                    @Override
                    public void onRatingChanged(SimpleRatingBar simpleRatingBar, float rating, boolean fromUser)
                    {
                        //keep the current rating at all times
                        mCurrentRate = (int) rating;
                        if (fromUser)
                        {

                            if (rating < 1)
                            {
                                //for this app we want a minimum rating of 1

                                //set the previous rating
                                vh.mRateNow.setRating(getOwnerRating());
                                Toast.makeText(RestaurantActivity.this, R.string.min_rating, Toast.LENGTH_SHORT).show();
                            }
                            else
                            {
                                //new rating was set, rate the restaurant
                                rateRestaurant();
                            }
                        }
                    }
                });

                if (isAnonymous())
                {
                    vh.mRateNow.setIndicator(true);

                    //setting the indicator will disable onClick listeners, so just listen to touch events
                    vh.mRateNow.setOnTouchListener(new View.OnTouchListener()
                    {
                        @Override
                        public boolean onTouch(View v, MotionEvent event)
                        {

                            switch (event.getActionMasked())
                            {
                                //only logged in users can use this feature
                                case MotionEvent.ACTION_DOWN:
                                    if (isAnonymous())
                                    {
                                        vh.mRateNow.setRating(0);
                                        showRatingDisabledDialog();
                                    }
                                    return true;
                            }

                            return false;
                        }
                    });
                }
                else
                {
                    vh.mRateNow.setIndicator(false);
                    vh.mRateNow.setOnTouchListener(null);
                }
                vh.mRateNow.setRating(getOwnerRating());
            }
            else if (holder instanceof ViewHolderItem)
            {
                final Review data = mDataSet.get(position - 1);
                ViewHolderItem vh = (ViewHolderItem) holder;


                String name = data.getName();
                vh.mName.setText(!TextUtils.isEmpty(name) ? name : getString(R.string.unknown));

                String date = data.dateToString();
                vh.mDate.setText(!TextUtils.isEmpty(date) ? date : getString(R.string.unknown));

                final String comment = data.getComment();
                vh.mMessage.setText(!TextUtils.isEmpty(comment) ? comment : getString(R.string.unknown));
                vh.mEditReview.setVisibility(data.isEditable() ? View.VISIBLE : GONE);
                vh.mEditReview.setOnClickListener(new View.OnClickListener()
                {
                    @Override
                    public void onClick(View v)
                    {
                        editReviewDialog(comment);
                    }
                });
            }
        }

        private int getOwnerRating()
        {
            return mOwnerReview == null ? 0 : mOwnerReview.getRate();
        }

        private String formatDecimal(double decimal)
        {
            if (decimal % 1 != 0)
            {
                return String.format(Locale.ENGLISH, "%.1f", decimal);
            }
            else
            {
                //the decimal is an integer (i.e "8.0"; show "8")
                return String.valueOf((int) decimal);
            }
        }

        private String getAddressString(String address)
        {
            try
            {
                String[] split = address.split(",");
                return split[0].trim() + ", " + split[1].trim() + ", \n" + split[2].trim();
            }
            catch (Exception e)
            {
                e.printStackTrace();
                Log.e(LOG_TAG, "getAddressString: couldn't parse address", e);
            }

            return address;
        }


        @Override
        public int getItemCount()
        {
            //if no data - show the header and 'no results'. otherwise, show the header and the reviews
            return (mDataSet == null || mDataSet.size() == 0) ? 2 : mDataSet.size() + 1;
        }

        @Override
        public int getItemViewType(int position)
        {
            if (mDataSet.size() == 0)
            {
                if (position == 0)
                {
                    return TYPE_HEADER;
                }
                else
                {
                    return TYPE_EMPTY;
                }
            }

            return position == 0 ? TYPE_HEADER : TYPE_ITEM;
        }

        class ViewHolderHeader extends RecyclerView.ViewHolder
        {
            private TextView mName;
            private TextView mOpeningTimes;
            private View mMap;
            private TextView mAverageRatingText;
            private SimpleRatingBar mAverageRating;
            private TextView mRatingsNumber;
            private TextView mAddress;
            private TextView mWebsite;
            private TextView mPhone;
            private SimpleRatingBar mRateNow;
            private ImageButton mAddReview;
            private ImageView mBackgroundImage;

            ViewHolderHeader(View itemView)
            {
                super(itemView);
                mAddReview = (ImageButton) itemView.findViewById(R.id.add_review);
                mName = (TextView) itemView.findViewById(R.id.restaurant_name);
                mOpeningTimes = (TextView) itemView.findViewById(R.id.opening_times);
                mMap = itemView.findViewById(R.id.map);
                mAverageRatingText = (TextView) itemView.findViewById(R.id.average_rating_text);
                mAverageRating = (SimpleRatingBar) itemView.findViewById(R.id.average_rating_bar);
                mRatingsNumber = (TextView) itemView.findViewById(R.id.rating_number);
                mAddress = (TextView) itemView.findViewById(R.id.address);
                mWebsite = (TextView) itemView.findViewById(R.id.website);
                mPhone = (TextView) itemView.findViewById(R.id.phone);
                mRateNow = (SimpleRatingBar) itemView.findViewById(R.id.rate_bar);
                mBackgroundImage = (ImageView) itemView.findViewById(R.id.restaurant_image);
            }
        }

        class ViewHolderItem extends RecyclerView.ViewHolder
        {
            private TextView mName;
            private TextView mDate;
            private TextView mMessage;
            private View mEditReview;

            ViewHolderItem(View itemView)
            {
                super(itemView);
                mName = (TextView) itemView.findViewById(R.id.review_name);
                mDate = (TextView) itemView.findViewById(R.id.review_date);
                mMessage = (TextView) itemView.findViewById(R.id.review_msg);
                mEditReview = itemView.findViewById(R.id.edit_review);
            }
        }

        class EmptyViewHolder extends RecyclerView.ViewHolder
        {
            EmptyViewHolder(View itemView)
            {
                super(itemView);
            }
        }
    }

}
