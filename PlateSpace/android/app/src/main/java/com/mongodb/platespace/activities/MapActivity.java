package com.mongodb.platespace.activities;

import android.Manifest;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.location.Location;
import android.os.Bundle;
import android.support.v4.app.ActivityCompat;
import android.support.v7.widget.Toolbar;
import android.view.MenuItem;
import android.widget.Toast;

import com.google.android.gms.maps.CameraUpdateFactory;
import com.google.android.gms.maps.GoogleMap;
import com.google.android.gms.maps.OnMapReadyCallback;
import com.google.android.gms.maps.SupportMapFragment;
import com.google.android.gms.maps.model.LatLng;
import com.google.android.gms.maps.model.LatLngBounds;
import com.google.android.gms.maps.model.Marker;
import com.google.android.gms.maps.model.MarkerOptions;
import com.mongodb.platespace.R;
import com.mongodb.platespace.model.Restaurant;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;

/**
 * Map Activity to show restaurants.
 * This map activity supports a single restaurant or a list of restaurants
 */
public class MapActivity extends LoggedInActivity implements OnMapReadyCallback, GoogleMap.OnMapLoadedCallback
{
    private static final int MAP_PADDING = 150;
    public static final String KEY_SINGLE_RESTAURANT = "SINGLE_RESTAURANT";
    public static final String KEY_MULTIPLE_RESTAURANT = "MULTIPLE_RESTAURANT";

    private GoogleMap mMap;
    private Restaurant mRestaurant;
    private ArrayList<Restaurant> mRestaurantList;
    private Map<Marker, Restaurant> mRestaurantMap = new HashMap<>();

    public static Intent newIntent(Context context, Restaurant restaurant)
    {
        Intent intent = new Intent(context, MapActivity.class);
        intent.putExtra(KEY_SINGLE_RESTAURANT, restaurant);
        return intent;
    }

    public static Intent newIntent(Context context, ArrayList<Restaurant> dataSet)
    {
        Bundle bundle = new Bundle();
        bundle.putParcelableArrayList(KEY_MULTIPLE_RESTAURANT, dataSet);
        Intent intent = new Intent(context, MapActivity.class);
        intent.putExtra(KEY_MULTIPLE_RESTAURANT, dataSet);
        return intent;
    }

    @SuppressWarnings("unchecked")
    @Override
    protected void onCreate(Bundle savedInstanceState)
    {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_map);
        Toolbar myToolbar = (Toolbar) findViewById(R.id.my_toolbar);
        myToolbar.setTitle(R.string.title_activity_map);
        setSupportActionBar(myToolbar);
        if (getSupportActionBar() != null)
        {
            getSupportActionBar().setDisplayHomeAsUpEnabled(true);
        }

        // Obtain the SupportMapFragment and get notified when the map is ready to be used.
        SupportMapFragment mapFragment = (SupportMapFragment) getSupportFragmentManager()
                .findFragmentById(R.id.map);
        mapFragment.getMapAsync(this);

        Intent intent = getIntent();
        if (intent != null && intent.getExtras() != null)
        {
            mRestaurant = intent.getExtras().getParcelable(KEY_SINGLE_RESTAURANT);
            mRestaurantList = intent.getExtras().getParcelableArrayList(KEY_MULTIPLE_RESTAURANT);
        }

        if (mRestaurant != null)
        {
            myToolbar.setTitle(mRestaurant.getName());
        }
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

    /**
     * Manipulates the map once available.
     * This callback is triggered when the map is ready to be used.
     * This is where we can add markers or lines, add listeners or move the camera. In this case,
     * we just add a marker near Sydney, Australia.
     * If Google Play services is not installed on the device, the user will be prompted to install
     * it inside the SupportMapFragment. This method will only be triggered once the user has
     * installed Google Play services and returned to the app.
     */
    @Override
    public void onMapReady(GoogleMap googleMap)
    {
        mMap = googleMap;
        mMap.setOnMarkerClickListener(new GoogleMap.OnMarkerClickListener()
        {
            @Override
            public boolean onMarkerClick(Marker marker)
            {
                Restaurant restaurant = mRestaurantMap.get(marker);
                if (restaurant != null)
                {
                    if (restaurant == mRestaurant)
                    {
                        /*
                        we showed a single restaurant and the user clicked the marker, use the
                        default behavior.
                         */
                        return false;
                    }
                    else
                    {
                        /*
                        * User clicked on a single restaurant out of the list of restaurants,
                         * so go the restaurant page */
                        startActivity(RestaurantActivity.newIntent(MapActivity.this, restaurant));
                    }
                    return true;
                }
                return false;
            }
        });

        if (ActivityCompat.checkSelfPermission(this, Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED)
        {
            mMap.setMyLocationEnabled(true);
        }

        mMap.setOnMapLoadedCallback(this);
    }

    @Override
    public void onMapLoaded()
    {
        LatLngBounds.Builder builder = new LatLngBounds.Builder();
        if (mRestaurantList != null)
        {
            for (Restaurant restaurant : mRestaurantList)
            {
                //add the restaurant to the map
                addRestaurant(restaurant, builder);
            }
        }

        addRestaurant(mRestaurant, builder);

        /*
        * Set the zoom level to show all markers */
        if (!mRestaurantMap.isEmpty())
        {
            LatLngBounds bounds = builder.build();
            mMap.animateCamera(CameraUpdateFactory.newLatLngBounds(bounds, MAP_PADDING));
        }
        else
        {
            Toast.makeText(this, R.string.no_results, Toast.LENGTH_SHORT).show();
        }
    }

    private void addRestaurant(Restaurant restaurant, LatLngBounds.Builder builder)
    {
        if (restaurant != null && restaurant.getLocation() != null)
        {
            Location location = restaurant.getLocation();

            LatLng latLng = new LatLng(location.getLatitude(), location.getLongitude());
            builder.include(latLng);
            MarkerOptions options = new MarkerOptions().position(latLng).title(restaurant.getName());
            Marker marker = mMap.addMarker(options);

            //keep the marker so we can get it's corresponding restaurant when clicked
            mRestaurantMap.put(marker, restaurant);
        }
    }
}
