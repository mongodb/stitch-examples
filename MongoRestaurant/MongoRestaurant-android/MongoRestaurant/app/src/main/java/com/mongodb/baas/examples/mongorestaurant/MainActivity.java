package com.mongodb.stitch.examples.mongorestaurant;

import android.content.DialogInterface;
import android.os.Bundle;
import android.support.annotation.NonNull;
import android.support.v7.app.AlertDialog;
import android.support.v7.app.AppCompatActivity;
import android.text.InputType;
import android.util.Log;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ListView;
import android.widget.TextView;

import com.google.android.gms.tasks.Continuation;
import com.google.android.gms.tasks.OnCompleteListener;
import com.google.android.gms.tasks.Task;

import com.mongodb.stitch.android.StitchClient;
import com.mongodb.stitch.android.auth.Auth;
import com.mongodb.stitch.android.auth.AvailableAuthProviders;
import com.mongodb.stitch.android.auth.anonymous.AnonymousAuthProvider;
import com.mongodb.stitch.android.services.mongodb.MongoClient;

import org.bson.Document;

import java.util.ArrayList;
import java.util.List;

public class MainActivity extends AppCompatActivity {

    // Remember to replace the APP_ID with your Stitch Application ID

    private static final String APP_ID = "STITCH-APP-ID"; //The Stitch Application ID
    private static final String TAG = "STITCH-SDK";
    private static final String MONGODB_SERVICE_NAME = "MONGODB-SERVICE-NAME";

    private StitchClient _client;
    private MongoClient _mongoClient;

    private String currentRestaurantName;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        _client = new StitchClient(this.getBaseContext(), APP_ID);
        _mongoClient = new MongoClient(_client, MONGODB_SERVICE_NAME);

        currentRestaurantName = "";
        doAnonymousAuthentication();
    }

    private void doAnonymousAuthentication() {

        _client.getAuthProviders().addOnCompleteListener(new OnCompleteListener<AvailableAuthProviders>() {
            @Override
            public void onComplete(@NonNull final Task<AvailableAuthProviders> task) {
                if (!task.isSuccessful()){
                    Log.e(TAG, "Could not retrieve authentication providers");
                } else {
                    Log.i(TAG, "Retrieved authentication providers");

                    if (task.getResult().hasAnonymous()){
                        _client.logInWithProvider(new AnonymousAuthProvider()).continueWith(new Continuation<Auth, Object>() {
                            @Override
                            public Object then(@NonNull final Task<Auth> task) throws Exception {
                                if (task.isSuccessful()) {
                                    Log.i(TAG,"User Authenticated as " + _client.getAuth().getUser().getId());
                                } else {
                                    Log.e(TAG, "Error logging in anonymously", task.getException());
                                }
                                return null;
                            }
                        });
                    }
                }
            }
        });
    }

    public void searchRestaurant(View view){

        if (!_client.isAuthenticated()){
            warnAuth();
        } else {

            final EditText restaurant = (EditText) findViewById(R.id.searchName);
            currentRestaurantName = restaurant.getText().toString();

            if (currentRestaurantName.matches("")){
                new AlertDialog.Builder(this)
                        .setTitle("Invalid restaurant")
                        .setMessage("Please specify a restaurant name. Try searching again.")
                        .setPositiveButton(android.R.string.yes, new DialogInterface.OnClickListener() {
                            public void onClick(DialogInterface dialog, int which) {
                            }
                        })
                        .setIcon(android.R.drawable.ic_dialog_alert)
                        .show();
                return;
            }

            final Document query = new Document( "name",currentRestaurantName);
            Log.i(TAG, "Restaurant search query:" + query);

            // This code block is a simple find() command on the "restaurants" collection in the "guidebook" database.
            // The application only cares about the first returned result, even if there are multiple matches.

            _mongoClient.getDatabase("guidebook").getCollection("restaurants").find(query).continueWith(new Continuation<List<Document>, Object>() {

                @Override
                public Object then(@NonNull final Task<List<Document>> task) throws Exception {
                    if (!task.isSuccessful()){
                        Log.e(TAG,"Failed to execute query");
                    } else {
                        TextView res = (TextView) findViewById(R.id.resultFound);

                        if (task.getResult().size() == 0) {
                            res.setText("No results found");
                            Log.i(TAG, "Query failed to return any results");
                            clearComments();
                            return null;
                        }
                        res.setText("Restaurant found");

                        final Document doc = task.getResult().get(0);

                        final TextView cuisine = (TextView) findViewById(R.id.cuisine);
                        cuisine.setText(doc.get("cuisine").toString());

                        final TextView location = (TextView) findViewById(R.id.location);
                        location.setText(doc.get("location").toString());

                        final List<Document> comments = (List<Document>) doc.get("comments");
                        if (comments.size() > 0) {

                            // showComments() passes the list of documents to a custom list adapter.
                            // It then passes the list adapter to a list view, where the comments are displayed.
                            showComments(comments);
                        } else {
                            clearComments();
                        }
                    }
                    return null;
                }
            });
        }
    }

    private void clearComments() {

        final ListView lv = (ListView) findViewById(R.id.commentList);
        lv.setAdapter(null);

    }

    public void writeComment(final View view) {

        // Its important to check for authentication, as the authenticated user ID is used as
        // part of the document.
        if (!_client.isAuthenticated()){
            warnAuth();
            return;
        }

        if (currentRestaurantName.matches("")){
            warnSearch();
            return;
        }

        final EditText input = new EditText(this);
        input.setInputType(InputType.TYPE_CLASS_TEXT);

        final AlertDialog.Builder builder = new AlertDialog.Builder(this);
        builder.setTitle("Write Comment");
        builder.setView(input);
        builder.setPositiveButton("OK", new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialog, int which) {

                // The query document uses the name of the currently displayed restaurant
                final Document query = new Document("name",currentRestaurantName);

                // This is specific to anonymous authentication.
                // For facebook or google, you can check for a username using _client.getAuth().getUser.getData().get("name")
                final Document newComment = new Document("user_id", _client.getAuth().getUser().getId());
                newComment.put("comment" , input.getText().toString());

                // The $push update operator adds the "newComment" document to the "comment" array.
                // If "comment" does not exist, $push creates the array and adds "newComment" to it.
                final Document update = new Document( "$push" , new Document("comments", newComment));

                // This code block performs an "updateOne" operation, updating the document associated to the currently selected restaurant and adding a new comment to the "comment" array.
                // On success, it calls "refreshComments()", which refreshes the List View displaying the comments associated to the restaurant.
                _mongoClient.getDatabase("guidebook").getCollection("restaurants").updateOne(query,update).continueWith(new Continuation<Void, Object>() {
                    @Override
                    public Object then(@NonNull final Task<Void> task) {
                        if (task.isSuccessful()) {
                            refreshComments(view);
                        } else {
                            Log.e(TAG,"Error writing comment");
                        }
                        return null;
                    }
                });

            }
        });
        builder.setNegativeButton("Cancel", new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialog, int which) {
                dialog.cancel();
            }
        });

        builder.show();
    }

    public void refreshComments(View view) {

        if (currentRestaurantName.matches("")){
            warnSearch();
            return;
        }

        final Document query = new Document("name",currentRestaurantName);

        _mongoClient.getDatabase("guidebook").getCollection("restaurants").find(query).continueWith(new Continuation<List<Document>, Object>() {
            @Override
            public Object then(@NonNull final Task<List<Document>> task) {
                if (!task.isSuccessful()){
                    Log.e(TAG, "Error refreshing comments");
                } else {

                    final Document result = task.getResult().get(0);
                    final List<Document> comments = (List<Document>) result.get("comments");

                    if (comments.size() > 0 ){
                        showComments(comments);
                    } else {
                        clearComments();
                    }
                }
                return null;
            }
        });
    }

    private void showComments(List<Document> comments) {

        final CustomListAdapter cla = new CustomListAdapter(this,comments);

        final ListView lv = (ListView) findViewById(R.id.commentList);
        lv.setAdapter(cla);
    }

    private void warnAuth() {
        new AlertDialog.Builder(this)
                .setTitle("Not Authenticated")
                .setMessage("The application automatically performs anonymous authentication. If you continue to see this message, check for network connectivity")
                .setPositiveButton(android.R.string.yes, new DialogInterface.OnClickListener() {
                    public void onClick(DialogInterface dialog, int which) {
                    }
                })
                .setIcon(android.R.drawable.ic_dialog_alert)
                .show();
        return;
    }

    private void warnSearch() {
        new AlertDialog.Builder(this)
                .setTitle("Invalid restaurant")
                .setMessage("You can only read or write comments for a valid restaurant. Try searching again.")
                .setPositiveButton(android.R.string.yes, new DialogInterface.OnClickListener() {
                    public void onClick(DialogInterface dialog, int which) {
                    }
                })
                .setIcon(android.R.drawable.ic_dialog_alert)
                .show();
        return;
    }

}