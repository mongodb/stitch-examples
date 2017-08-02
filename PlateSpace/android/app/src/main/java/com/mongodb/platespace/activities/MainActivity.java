package com.mongodb.platespace.activities;

import android.app.Dialog;
import android.app.SearchManager;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.location.Location;
import android.os.Bundle;
import android.support.annotation.NonNull;
import android.support.annotation.Nullable;
import android.support.v4.view.MenuItemCompat;
import android.support.v7.app.AlertDialog;
import android.support.v7.widget.DividerItemDecoration;
import android.support.v7.widget.LinearLayoutManager;
import android.support.v7.widget.RecyclerView;
import android.support.v7.widget.SearchView;
import android.support.v7.widget.Toolbar;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.view.ViewGroup;
import android.view.inputmethod.InputMethodManager;
import android.widget.ListView;
import android.widget.TextView;
import android.widget.Toast;

import com.mongodb.platespace.R;
import com.mongodb.platespace.interfaces.LocationListener;
import com.mongodb.platespace.interfaces.QueryListener;
import com.mongodb.platespace.model.Attributes;
import com.mongodb.platespace.model.Restaurant;
import com.mongodb.platespace.mongodb.MongoDBManager;
import com.mongodb.platespace.utils.ProgressDialog;
import com.paginate.Paginate;

import java.util.ArrayList;
import java.util.List;
import java.util.Locale;


/**
 * Main activity to show the restaurants in the DB
 */
public class MainActivity extends LoggedInActivity
{
    private static final String TAG = MainActivity.class.getSimpleName();
    private static final String EXTRA_RESTAURANT = "EXTRA_RESTAURANT";
    private static final int REQUEST_CODE = 726;

    private MenuItem mSearchMenuItem;

    private static final int PAGE_SIZE = 50;
    private RecyclerView mRecyclerView;
    private RestaurantAdapter mAdapter;
    private SearchView mSearchView;
    private Attributes mAttributesFilter;

    private AlertDialog mFilterDialog;
    private Location mLastLocation;
    private boolean mIsLoading;

    private boolean mIsFinished;
    private Restaurant mFarthestRestaurant;

    private Paginate mPaginate;

    private String mKeyword;
    private boolean mIsProgressDialogShowing = false;


    public static Intent fromRestaurantActivity(Restaurant restaurant)
    {
        Intent intent = new Intent();
        intent.putExtra(EXTRA_RESTAURANT, restaurant);
        return intent;
    }

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState)
    {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        Toolbar myToolbar = (Toolbar) findViewById(R.id.my_toolbar);
        setSupportActionBar(myToolbar);
        mAttributesFilter = new Attributes();
        initRecyclerView();
    }

    @Override
    public void onConnected(@Nullable Bundle bundle)
    {
        super.onConnected(bundle);

        //update the location of the device
        updateLocation();
    }

    @Override
    protected void onLocationPermissionGranted()
    {
        super.onLocationPermissionGranted();
        updateLocation();
    }

    private void updateLocation()
    {
        /*
        * get the last location of the device
        * */
        getLastLocation(new LocationListener()
        {
            @Override
            public void onLocationReceived(Location location)
            {
                mLastLocation = location;
                if (mLastLocation != null && mAdapter != null)
                {

                    /*once we have a location, add the pagination mechanism and continue*/
                    if (mPaginate == null)
                    {
                        mPaginate = Paginate.with(mRecyclerView, mPaginateCallback)
                                .setLoadingTriggerThreshold(2)
                                .build();
                    }
                    mRecyclerView.getAdapter().notifyDataSetChanged();
                }
            }
        });

    }

    @Override
    public boolean onPrepareOptionsMenu(Menu menu)
    {
        MenuItem filterItem = menu.findItem(R.id.menu_filter);
        filterItem.setIcon(filterEnabled() ? R.drawable.ic_filter_selected : R.drawable.ic_filter_normal);
        MenuItem mapItem = menu.findItem(R.id.menu_map);

        boolean hasResults = mAdapter != null && mAdapter.getDataSet() != null && !mAdapter.getDataSet().isEmpty();
        mapItem.setEnabled(hasResults);
        openSearchView();
        return super.onPrepareOptionsMenu(menu);
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu)
    {
        super.onCreateOptionsMenu(menu);
        getMenuInflater().inflate(R.menu.options_menu, menu);

        SearchManager searchManager =
                (SearchManager) getSystemService(Context.SEARCH_SERVICE);

        mSearchMenuItem = menu.findItem(R.id.menu_search);

        /* onCloseListener doesn't work.
          Workaround as suggested in http://stackoverflow.com/questions/9327826/searchviews-oncloselistener-doesnt-work
         */
        MenuItemCompat.setOnActionExpandListener(mSearchMenuItem, new MenuItemCompat.OnActionExpandListener()
        {
            @Override
            public boolean onMenuItemActionExpand(MenuItem item)
            {
                return true;
            }

            @Override
            public boolean onMenuItemActionCollapse(MenuItem item)
            {

                /*
                * clear previous results
                * */
                mAdapter.clear();
                mFarthestRestaurant = null;
                mKeyword = null;

                //get the restaurants
                getRestaurants(true, true);
                return true;
            }
        });
        mSearchView = (SearchView) MenuItemCompat.getActionView(mSearchMenuItem);

        mSearchView.setQueryHint(getString(R.string.search));
        mSearchView.setOnQueryTextListener(new SearchView.OnQueryTextListener()
        {
            @Override
            public boolean onQueryTextSubmit(String query)
            {
                //close the keyboard after the search
                closeKeyboard();

                //need a dummy view to request focus so that the search EditText doesn't pop the keyboard back up
                mRecyclerView.requestFocus();

                //clear previous restaurants
                mAdapter.clear();
                mFarthestRestaurant = null;

                mKeyword = query;

                //get list of restaurants with search query
                getRestaurants(true, true);
                return true;
            }

            @Override
            public boolean onQueryTextChange(String newText)
            {
                return false;
            }
        });
        mSearchView.setSearchableInfo(searchManager.getSearchableInfo(getComponentName()));
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item)
    {
        switch (item.getItemId())
        {
            case R.id.menu_filter:
                showFilterDialog();
                break;
            case R.id.menu_map:
                openMap();
                break;
            case R.id.menu_log_out:
                showLogoutDialog();
                break;
        }

        return super.onOptionsItemSelected(item);
    }

    private void openSearchView()
    {
        if (mKeyword != null)
        {
            MenuItemCompat.expandActionView(mSearchMenuItem);
            mSearchView.setQuery(mKeyword, false);
            mSearchView.clearFocus();
        }
    }

    private void showLogoutDialog()
    {
        AlertDialog.Builder builder = new AlertDialog.Builder(this, R.style.DialogTheme);
        builder.setTitle(R.string.log_out)
                .setMessage(R.string.log_out_message)
                .setPositiveButton(R.string.cancel, new DialogInterface.OnClickListener()
                {
                    @Override
                    public void onClick(DialogInterface dialog, int which)
                    {
                        dialog.dismiss();
                    }
                })
                .setNegativeButton(R.string.log_out, new DialogInterface.OnClickListener()
                {
                    @Override
                    public void onClick(DialogInterface dialog, int which)
                    {
                        dialog.dismiss();
                        logout();
                    }
                }).show();
    }


    private void logout()
    {
        final Dialog dialog = ProgressDialog.getDialog(this, false);
        dialog.show();
        mIsProgressDialogShowing = true;
        mAdapter.notifyDataSetChanged();

        //logout from application
        MongoDBManager.getInstance(getApplicationContext())
                .logout(new QueryListener<Void>()
                {
                    @Override
                    public void onSuccess(Void result)
                    {
                        dialog.dismiss();
                        mIsProgressDialogShowing = false;
                        startActivity(SignInActivity.newIntent(MainActivity.this));
                        finish();
                    }

                    @Override
                    public void onError(Exception e)
                    {
                        Log.e(TAG, "onError: unable to logout", e);
                        dialog.dismiss();
                        mIsProgressDialogShowing = false;
                        Toast.makeText(MainActivity.this, "Unable to logout", Toast.LENGTH_LONG).show();
                    }
                });
    }

    private void closeKeyboard()
    {
        InputMethodManager imm = (InputMethodManager) getSystemService(Context.INPUT_METHOD_SERVICE);
        imm.hideSoftInputFromWindow(mSearchView.getWindowToken(), 0);
    }

    private void openMap()
    {
        /*
        Open the map with the restaurants that are currently visible
        */

        Intent intent = MapActivity.newIntent(this, mAdapter.getDataSet());
        startActivity(intent);
    }

    private boolean filterEnabled()
    {
        return mAttributesFilter.filterEnabled();
    }

    private void showFilterDialog()
    {
        /*
        * Show the user a dialog with the available filters.
        * Once the filters are applied, a new search will begin.
        * */
        String[] filters = getResources().getStringArray(R.array.filter_attributes);
        final Attributes previousFilter = mAttributesFilter.copy();
        final boolean[] filterArray = mAttributesFilter.toArray();

        AlertDialog.Builder builder = new AlertDialog.Builder(this, R.style.DialogTheme);
        mFilterDialog = builder.setTitle(getString(R.string.filter).toUpperCase())
                .setNegativeButton(R.string.cancel, new DialogInterface.OnClickListener()
                {
                    @Override
                    public void onClick(DialogInterface dialog, int which)
                    {
                        mAttributesFilter = previousFilter.copy();
                        dialog.dismiss();
                    }
                })
                .setPositiveButton(R.string.apply, new DialogInterface.OnClickListener()
                {
                    @Override
                    public void onClick(DialogInterface dialog, int which)
                    {
                        //add the filter
                        mAttributesFilter = Attributes.fromArray(filterArray);
                        mFarthestRestaurant = null;

                        //get the restaurants with the new filters
                        getRestaurants(true, true);
                        dialog.dismiss();
                    }
                }).setMultiChoiceItems(filters, filterArray,
                        new DialogInterface.OnMultiChoiceClickListener()
                        {
                            @Override
                            public void onClick(DialogInterface dialog, int which, boolean isChecked)
                            {
                                filterArray[which] = isChecked;
                                if (which == 0)
                                {
                                    for (int i = 1; i < filterArray.length; i++)
                                    {
                                        filterArray[i] = isChecked;
                                        mFilterDialog.getListView().setItemChecked(i, isChecked);
                                    }
                                }
                                else
                                {
                                    boolean allFull = true;
                                    for (int i = 1; i < filterArray.length; i++)
                                    {
                                        allFull = allFull && filterArray[i];
                                    }

                                    filterArray[0] = allFull;
                                    mFilterDialog.getListView().setItemChecked(0, allFull);
                                }

                            }
                        })
                .setOnDismissListener(new DialogInterface.OnDismissListener()
                {
                    @Override
                    public void onDismiss(DialogInterface dialog)
                    {
                        invalidateOptionsMenu();
                    }
                }).create();
        mFilterDialog.getListView().setChoiceMode(ListView.CHOICE_MODE_MULTIPLE);
        mFilterDialog.show();

    }

    private boolean isSearching()
    {
        /*
        * Simple way to know if we are currently in the 'search' mode
        * */
        return mSearchView != null && !mSearchView.isIconified();
    }

    private void initRecyclerView()
    {
        mRecyclerView = (RecyclerView) findViewById(R.id.recycler_view);
        final LinearLayoutManager layoutManager = new LinearLayoutManager(this);

        mRecyclerView.setHasFixedSize(false);
        mRecyclerView.setLayoutManager(layoutManager);

        DividerItemDecoration divider = new DividerItemDecoration(this, layoutManager.getOrientation());
        mRecyclerView.addItemDecoration(divider);
        mAdapter = new RestaurantAdapter();
        mAdapter.setLoading(true);
        mRecyclerView.setAdapter(mAdapter);
    }


    /*
    * Callbacks for RecyclerView pagination
    * */
    private Paginate.Callbacks mPaginateCallback = new Paginate.Callbacks()
    {
        @Override
        public void onLoadMore()
        {
            /*
            * Get the next page of restaurants
            * */
            getRestaurants(false, false);
        }

        @Override
        public boolean isLoading()
        {
            /*
            loading indication for the pagination adapter
            */
            return mIsLoading && !isSearching() && !mIsProgressDialogShowing;
        }

        @Override
        public boolean hasLoadedAllItems()
        {
            /*
            * indication of whether we finished the pagination or not
            * */
            return mLastLocation != null && (mIsFinished || isSearching());
        }
    };


    private void getRestaurants(/*@Nullable String keyword, */boolean withProgressDialog, final boolean clearList)
    {
        if (mLastLocation == null)
        {
            Toast.makeText(this, R.string.location_error, Toast.LENGTH_SHORT).show();
            return;
        }


        mIsLoading = true;
        mAdapter.setLoading(true);

        final Dialog dialog = withProgressDialog ? ProgressDialog.getDialog(this, false) : null;
        if (dialog != null)
        {
            dialog.show();
            mIsProgressDialogShowing = true;
            mAdapter.notifyDataSetChanged();
        }

        /*
        Get a list of restaurants, sorted by the geo location (closest restaurants go first), filters and query regex (if not null)
        */
        MongoDBManager.getInstance(getApplicationContext()).geoNear(mKeyword, mAttributesFilter, mLastLocation.getLatitude()
                , mLastLocation.getLongitude(), mFarthestRestaurant, PAGE_SIZE, new QueryListener<List<Restaurant>>()
                {
                    @Override
                    public void onSuccess(List<Restaurant> restaurants)
                    {
                        mAdapter.setLoading(false);
                        mIsLoading = false;

                        //if the list of results is smaller than the page size, the pagination finished
                        mIsFinished = restaurants.size() < PAGE_SIZE;

                        if (dialog != null)
                        {
                            dialog.dismiss();
                            mIsProgressDialogShowing = false;
                        }

                        if (!restaurants.isEmpty())
                        {
                            /*
                            * update the farthest restaurant so we can use it for the next page
                            * */
                            mFarthestRestaurant = restaurants.get(restaurants.size() - 1);
                        }

                        //clear previous results
                        if (clearList)
                        {
                            mAdapter.clear();
                        }

                        mAdapter.addData(restaurants);
                        mAdapter.notifyDataSetChanged();
                    }

                    @Override
                    public void onError(Exception e)
                    {
                        mAdapter.setLoading(false);
                        mIsLoading = false;
                        mIsFinished = true;
                        mAdapter.notifyDataSetChanged();
                        Toast.makeText(MainActivity.this, R.string.unable_to_get_results, Toast.LENGTH_SHORT).show();
                        if (dialog != null)
                        {
                            dialog.dismiss();
                        }
                    }
                });
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data)
    {
        if (requestCode == REQUEST_CODE)
        {
            if (data != null && data.getExtras() != null)
            {
                //get the restaurant from the previous activity
                Restaurant restaurant = data.getExtras().getParcelable(EXTRA_RESTAURANT);
                if (mAdapter != null && restaurant != null)
                {
                    mAdapter.updateRestaurant(restaurant);
                }
            }
        }

        super.onActivityResult(requestCode, resultCode, data);
    }

    private class RestaurantAdapter extends RecyclerView.Adapter<RecyclerView.ViewHolder>
    {

        private static final int EMPTY_VIEW = 2;
        boolean mLoading;
        private ArrayList<Restaurant> mDataSet = new ArrayList<>();
        private RestaurantClickListener mClickListener = new RestaurantClickListener();

        RestaurantAdapter()
        {
        }

        void clear()
        {
            mDataSet.clear();
        }

        public void setData(List<Restaurant> dataSet)
        {
            mDataSet.clear();
            mDataSet.addAll(dataSet);
            notifyDataSetChanged();
            invalidateOptionsMenu();
        }

        void setLoading(boolean loading)
        {
            this.mLoading = loading;
        }

        ArrayList<Restaurant> getDataSet()
        {
            return mDataSet;
        }

        void addData(List<Restaurant> data)
        {
            mDataSet.addAll(data);
            invalidateOptionsMenu();
        }

        @Override
        public RecyclerView.ViewHolder onCreateViewHolder(ViewGroup parent, int viewType)
        {
            if (viewType == EMPTY_VIEW)
            {
                /* No results */
                View view = LayoutInflater.from(parent.getContext()).inflate(R.layout.empty_view, parent, false);
                return new EmptyViewHolder(view);
            }
            else
            {
                View root = LayoutInflater.from(parent.getContext()).inflate(R.layout.list_item_rest, parent, false);
                root.setOnClickListener(mClickListener);
                return new ViewHolder(root);
            }

        }

        @Override
        public void onBindViewHolder(RecyclerView.ViewHolder holder, int position)
        {
            /*
            Bind the restaurant to the UI
            * */

            if (holder instanceof ViewHolder)
            {
                ViewHolder vh = (ViewHolder) holder;
                Restaurant data = mDataSet.get(position);
                vh.mName.setText(data.getName());
                setAddress(vh, data.getAddress());
                vh.mPhone.setText(data.getPhone());
                if (mLastLocation != null)
                {
                    vh.mDistance.setText(formatDistance(data.getDistance()));
                }
                else
                {
                    vh.mDistance.setText(R.string.unknown);
                }
            }
        }

        /*In this app if the distance to the restaurant is bigger than 10 miles, we round the number.
        * If the distance is smaller than 10 miles, we wanna show the distance with 1 digit after the decimal point
         * (I.e 12.8 miles will be 12 miles,  7.823 will be 7.8 miles).*/
        private String formatDistance(double distanceMeters)
        {
            double miles = metersToMiles(distanceMeters);
            String formatDistance;
            if (miles > 10)
            {
                formatDistance = String.valueOf(Math.round(miles));
            }
            else
            {
                formatDistance = String.format(Locale.ENGLISH, "%.1f", miles);
            }

            return getString(R.string.distance_miles, formatDistance);
        }

        /*
        * Convert meters (unit used by MongoDB) to miles
        * */
        private double metersToMiles(double meters)
        {
            return meters * 0.000621371192;
        }

        private void setAddress(ViewHolder vh, String address)
        {
            try
            {
                String[] split = address.split(",");
                vh.mAddress.setText(split[0].trim() + ", " + split[1].trim());
                vh.mZipCode.setText(split[2].trim());

            }
            catch (Exception e)
            {
                Log.e(TAG, "unable to parse address", e);
            }
        }

        @Override
        public int getItemViewType(int position)
        {
            if (mDataSet.size() == 0)
            {
                /*
                * no results view
                * */
                return EMPTY_VIEW;
            }

            return super.getItemViewType(position);
        }

        @Override
        public int getItemCount()
        {
            if (mDataSet == null || mDataSet.size() == 0)
            {
                if (mLoading)
                {
                    return 0;
                }
                else
                {
                    return 1;
                }
            }

            return mDataSet.size();

        }

        void updateRestaurant(@NonNull Restaurant restaurant)
        {
            int index = mDataSet == null ? -1 : mDataSet.indexOf(restaurant);
            if (index > 0)
            {
                Restaurant oldRest = mDataSet.get(index);
                oldRest.setAverageRating(restaurant.getAverageRating());
                oldRest.setNumberOfRates(restaurant.getNumberOfRates());
                notifyDataSetChanged();
            }
        }

        class RestaurantClickListener implements View.OnClickListener
        {

            @Override
            public void onClick(View v)
            {
                int itemPosition = mRecyclerView.getChildLayoutPosition(v);
                Restaurant data = mDataSet.get(itemPosition);

                //get the restaurant and show it in the map activity
                Intent intent = RestaurantActivity.newIntent(MainActivity.this, data);
                startActivityForResult(intent, REQUEST_CODE);
            }
        }

        class EmptyViewHolder extends RecyclerView.ViewHolder
        {
            EmptyViewHolder(View itemView)
            {
                super(itemView);
            }
        }

        class ViewHolder extends RecyclerView.ViewHolder
        {
            TextView mName;
            TextView mAddress;
            TextView mZipCode;
            TextView mPhone;
            TextView mDistance;

            ViewHolder(View itemView)
            {
                super(itemView);
                mName = (TextView) itemView.findViewById(R.id.list_item_restaurant_name);
                mAddress = (TextView) itemView.findViewById(R.id.list_item_restaurant_address);
                mZipCode = (TextView) itemView.findViewById(R.id.list_item_restaurant_zip_code);
                mPhone = (TextView) itemView.findViewById(R.id.list_item_restaurant_phone);
                mDistance = (TextView) itemView.findViewById(R.id.list_item_restaurant_distance);
            }
        }
    }
}
