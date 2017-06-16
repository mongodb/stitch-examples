package com.mongodb.solomo.activities;

import android.Manifest;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.location.Location;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.provider.Settings;
import android.support.annotation.NonNull;
import android.support.annotation.Nullable;
import android.support.v4.app.ActivityCompat;
import android.support.v7.app.AlertDialog;
import android.text.TextUtils;
import android.util.Log;

import com.google.android.gms.common.ConnectionResult;
import com.google.android.gms.common.api.GoogleApiClient;
import com.google.android.gms.location.LocationCallback;
import com.google.android.gms.location.LocationRequest;
import com.google.android.gms.location.LocationResult;
import com.google.android.gms.location.LocationServices;
import com.mongodb.solomo.R;
import com.mongodb.solomo.interfaces.LocationListener;

/**
 * Activity for location handling.
 */

public class LoggedInActivity extends CalligraphyActivity implements GoogleApiClient.ConnectionCallbacks, GoogleApiClient.OnConnectionFailedListener
{
    private static final int LOCATION_REQUEST_CODE = 420;
    private static final String LOG_TAG = LoggedInActivity.class.getSimpleName();

    private GoogleApiClient mGoogleApiClient;
    private AlertDialog mLocationEnabledDialog;

    @Override
    public void onConnected(@Nullable Bundle bundle)
    {
        Log.d(LOG_TAG, "onConnected() called with: " + "bundle = [" + bundle + "]");
    }

    @Override
    public void onConnectionSuspended(int i)
    {
        Log.d(LOG_TAG, "onConnectionSuspended() called with: " + "i = [" + i + "]");
    }

    @Override
    public void onConnectionFailed(@NonNull ConnectionResult connectionResult)
    {
        Log.e(LOG_TAG, "onConnectionFailed: " + connectionResult.getErrorMessage());
    }

    protected void onLocationPermissionGranted()
    {
        Log.d(LOG_TAG, "onLocationPermissionGranted: ");
    }

    private void initGoogleLocationServices()
    {
        if (mGoogleApiClient == null)
        {
            mGoogleApiClient = new GoogleApiClient.Builder(this)
                    .addConnectionCallbacks(this)
                    .addOnConnectionFailedListener(this)
                    .addApi(LocationServices.API)
                    .build();
        }
    }

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState)
    {
        super.onCreate(savedInstanceState);
        initGoogleLocationServices();
    }

    @Override
    protected void onStart()
    {
        if (mGoogleApiClient != null)
        {
            mGoogleApiClient.connect();
        }
        super.onStart();
    }

    @Override
    protected void onStop()
    {
        if (mGoogleApiClient != null)
        {
            mGoogleApiClient.disconnect();
        }
        super.onStop();
    }

    @Override
    protected void onResume()
    {
        super.onResume();
        checkLocationPermission();
    }

    protected void getLastLocation(@NonNull LocationListener listener)
    {
        Location location = null;
        if (ActivityCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED)
        {
            location = LocationServices.FusedLocationApi.getLastLocation(mGoogleApiClient);
        }

        if (location == null)
        {
            startLocationUpdates(listener);
        }
        else
        {
            listener.onLocationReceived(location);
        }
    }

    private void startLocationUpdates(@NonNull final LocationListener listener)
    {
        if (ActivityCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED)
        {

            if (!mGoogleApiClient.isConnected())
            {
                mGoogleApiClient.connect();
                return;
            }

            LocationServices.FusedLocationApi.requestLocationUpdates(mGoogleApiClient, new LocationRequest().setPriority(LocationRequest.PRIORITY_HIGH_ACCURACY)
                    , new LocationCallback()
                    {
                        @Override
                        public void onLocationResult(LocationResult locationResult)
                        {
                            super.onLocationResult(locationResult);
                            Location lastLocation = locationResult.getLastLocation();
                            if (lastLocation != null)
                            {
                                LocationServices.FusedLocationApi.removeLocationUpdates(mGoogleApiClient, this);
                                listener.onLocationReceived(lastLocation);
                            }
                        }
                    }, getMainLooper());
        }
    }


    @Override
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults)
    {
        if (requestCode == LOCATION_REQUEST_CODE)
        {
            if (grantResults.length > 0 && grantResults[0] == PackageManager.PERMISSION_GRANTED)
            {
                //permission granted
                if (!isLocationEnabled())
                {
                    showLocationEnabledDialog();
                }
                else
                {
                    onLocationPermissionGranted();
                }
            }
        }

        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
    }

    private void showLocationPermissionDialog()
    {
        Log.d(LOG_TAG, "showLocationPermissionDialog: ");
        AlertDialog.Builder builder = new AlertDialog.Builder(this, R.style.DialogTheme);
        builder.setTitle(R.string.location_permission_dialog_title)
                .setMessage(R.string.location_permission_dialog_msg)
                .setCancelable(false)
                .setPositiveButton(R.string.ok, new DialogInterface.OnClickListener()
                {
                    @Override
                    public void onClick(DialogInterface dialog, int which)
                    {
                        dialog.dismiss();
                        ActivityCompat.requestPermissions(LoggedInActivity.this, new String[]{Manifest.permission.ACCESS_COARSE_LOCATION}, LOCATION_REQUEST_CODE);
                    }
                })
                .setNegativeButton(R.string.exit, new DialogInterface.OnClickListener()
                {
                    @Override
                    public void onClick(DialogInterface dialog, int which)
                    {
                        dialog.dismiss();
                        finish();
                    }
                })
                .setNeutralButton(R.string.location_permission_settings, new DialogInterface.OnClickListener()
                {
                    @Override
                    public void onClick(DialogInterface dialog, int which)
                    {
                        dialog.dismiss();
                        openAppPermissionsSettings();
                    }
                })
                .show();
    }

    private void showLocationEnabledDialog()
    {
        if (mLocationEnabledDialog != null && mLocationEnabledDialog.isShowing())
        {
            return;
        }

        Log.d(LOG_TAG, "showLocationEnabledDialog: ");
        AlertDialog.Builder builder = new AlertDialog.Builder(this, R.style.DialogTheme);
        builder.setTitle(R.string.location_enabled_dialog_title)
                .setMessage(R.string.location_enabled_dialog_msg)
                .setCancelable(false)
                .setPositiveButton(R.string.ok, new DialogInterface.OnClickListener()
                {
                    @Override
                    public void onClick(DialogInterface dialog, int which)
                    {
                        dialog.dismiss();
                        Intent locationIntent = new Intent(Settings.ACTION_LOCATION_SOURCE_SETTINGS);
                        startActivity(locationIntent);
                    }
                })
                .setNegativeButton(R.string.exit, new DialogInterface.OnClickListener()
                {
                    @Override
                    public void onClick(DialogInterface dialog, int which)
                    {
                        dialog.dismiss();
                        finish();
                    }
                });

        mLocationEnabledDialog = builder.create();
        mLocationEnabledDialog.show();

    }


    private void checkLocationPermission()
    {
        if (ActivityCompat.checkSelfPermission(this, Manifest.permission.ACCESS_COARSE_LOCATION) != PackageManager.PERMISSION_GRANTED)
        {
            showLocationPermissionDialog();
        }
        else
        {
            //permission granted - check if location is turned on
            if (!isLocationEnabled())
            {
                showLocationEnabledDialog();
            }
            else
            {
                onLocationPermissionGranted();
            }
        }
    }

    @SuppressWarnings("deprecation")
    private boolean isLocationEnabled()
    {
        int locationMode;
        String locationProviders;

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT)
        {
            try
            {
                locationMode = Settings.Secure.getInt(getContentResolver(), Settings.Secure.LOCATION_MODE);

            }
            catch (Settings.SettingNotFoundException e)
            {
                e.printStackTrace();
                return false;
            }

            return locationMode != Settings.Secure.LOCATION_MODE_OFF;

        }
        else
        {
            locationProviders = Settings.Secure.getString(getContentResolver(), Settings.Secure.LOCATION_PROVIDERS_ALLOWED);
            return !TextUtils.isEmpty(locationProviders);
        }
    }

    private void openAppPermissionsSettings()
    {
        Intent intent = new Intent();
        intent.setAction(Settings.ACTION_APPLICATION_DETAILS_SETTINGS);
        Uri uri = Uri.fromParts("package", getPackageName(), null);
        intent.setData(uri);
        startActivity(intent);

    }

}
