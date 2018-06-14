package com.mongodb.stitch.sdk.examples.todo;

import android.app.AlertDialog;
import android.content.DialogInterface;
import android.content.Intent;
import android.os.Bundle;
import android.os.Handler;
import android.support.annotation.NonNull;
import android.support.v7.app.AppCompatActivity;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.EditText;
import android.widget.ListView;

import com.facebook.AccessToken;
import com.facebook.CallbackManager;
import com.facebook.FacebookCallback;
import com.facebook.FacebookException;
import com.facebook.login.LoginManager;
import com.facebook.login.LoginResult;
import com.google.android.gms.auth.api.signin.GoogleSignInOptions;
import com.google.android.gms.auth.api.signin.GoogleSignInResult;
import com.google.android.gms.common.ConnectionResult;
import com.google.android.gms.common.api.GoogleApiClient;
import com.google.android.gms.common.api.ResultCallback;
import com.google.android.gms.common.api.Status;
import com.google.android.gms.tasks.OnCompleteListener;
import com.google.android.gms.tasks.Task;
import com.google.android.gms.tasks.TaskCompletionSource;
import com.google.android.gms.tasks.Tasks;

import com.mongodb.stitch.android.core.auth.StitchUser;
import com.mongodb.stitch.android.services.mongodb.remote.RemoteFindIterable;
import com.mongodb.stitch.android.services.mongodb.remote.RemoteMongoClient;
import com.mongodb.stitch.android.services.mongodb.remote.RemoteMongoCollection;
import com.mongodb.stitch.android.core.Stitch;
import com.mongodb.stitch.android.core.auth.StitchAuth;
import com.mongodb.stitch.android.core.auth.StitchAuthListener;
import com.mongodb.stitch.android.core.StitchAppClient;
import com.mongodb.stitch.core.auth.providers.anonymous.AnonymousCredential;
import com.mongodb.stitch.core.auth.providers.facebook.FacebookCredential;
import com.mongodb.stitch.core.auth.providers.google.GoogleCredential;
import com.mongodb.stitch.core.services.mongodb.remote.RemoteInsertOneResult;

import org.bson.Document;

import java.lang.ref.WeakReference;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import static com.google.android.gms.auth.api.Auth.GOOGLE_SIGN_IN_API;
import static com.google.android.gms.auth.api.Auth.GoogleSignInApi;

public class MainActivity extends AppCompatActivity {

    private static final String TAG = "TodoApp";
    private static final int RC_SIGN_IN = 421;

    private CallbackManager _callbackManager;
    private GoogleApiClient _googleApiClient;
    private StitchAppClient _client;
    private RemoteMongoClient _mongoClient;

    private TodoListAdapter _itemAdapter;
    private Handler _handler;
    private Runnable _refresher;

    private boolean _fbInitOnce;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        _handler = new Handler();
        _refresher = new ListRefresher(this);

        this._client = Stitch.getDefaultAppClient();
        this._client.getAuth().addAuthListener(new MyAuthListener(this));

        _mongoClient = this._client.getServiceClient(RemoteMongoClient.Factory, "mongodb-atlas");
        setupLogin();
    }

    private static class MyAuthListener implements StitchAuthListener {

        private WeakReference<MainActivity> _main;
        private StitchUser _user;

        public MyAuthListener(final MainActivity activity) {
            _main = new WeakReference<>(activity);
        }

        @Override
        public void onAuthEvent(final StitchAuth auth) {
            if (auth.isLoggedIn() && _user == null) {
                Log.d(TAG, "Logged into Stitch");
                _user = auth.getUser();
                return;
            }

            if (!auth.isLoggedIn() && _user != null) {
                _user = null;
                onLogout();
            }
        }

        public void onLogout() {
            final MainActivity activity = _main.get();

            final List<Task<Void>> futures = new ArrayList<>();
            if (activity != null) {
                activity._handler.removeCallbacks(activity._refresher);

                if (activity._googleApiClient != null) {
                    final TaskCompletionSource<Void> future = new TaskCompletionSource<>();
                    GoogleSignInApi.signOut(
                            activity._googleApiClient).setResultCallback(new ResultCallback<Status>() {
                        @Override
                        public void onResult(@NonNull final Status ignored) {
                            future.setResult(null);
                        }
                    });
                    futures.add(future.getTask());
                }

                if (activity._fbInitOnce) {
                    LoginManager.getInstance().logOut();
                }

                Tasks.whenAll(futures).addOnCompleteListener(new OnCompleteListener<Void>() {
                    @Override
                    public void onComplete(@NonNull final Task<Void> ignored) {
                        activity.setupLogin();
                    }
                });
            }
        }
    }

    private static class ListRefresher implements Runnable {

        private WeakReference<MainActivity> _main;

        private ListRefresher(final MainActivity activity) {
            _main = new WeakReference<>(activity);
        }

        @Override
        public void run() {
            final MainActivity activity = _main.get();
            if (activity != null && activity._client.getAuth().isLoggedIn()) {
                activity.refreshList();
            }
        }
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);

        if (requestCode == RC_SIGN_IN) {
            final GoogleSignInResult result = GoogleSignInApi.getSignInResultFromIntent(data);
            handleGooglSignInResult(result);
            return;
        }

        if (_callbackManager != null) {
            _callbackManager.onActivityResult(requestCode, resultCode, data);
            return;
        }
        Log.e(TAG, "Nowhere to send activity result for ourselves");
    }

    private void handleGooglSignInResult(final GoogleSignInResult result) {
        if (result == null) {
            Log.e(TAG, "Got a null GoogleSignInResult");
            return;
        }

        Log.d(TAG, "handleGooglSignInResult:" + result.isSuccess());
        if (result.isSuccess()) {
            final GoogleCredential googleCredential = new GoogleCredential(result.getSignInAccount().getServerAuthCode());
            _client.getAuth().loginWithCredential(googleCredential).addOnCompleteListener(new OnCompleteListener<StitchUser>() {
                @Override
                public void onComplete(@NonNull final Task<StitchUser> task) {
                    if (task.isSuccessful()) {
                        initTodoView();
                    } else {
                        Log.e(TAG, "Error logging in with Google", task.getException());
                    }
                }
            });
        }
    }

    private void initTodoView() {
        setContentView(R.layout.activity_main_todo_list);
        // Set up items
        _itemAdapter = new TodoListAdapter(
                this,
                R.layout.todo_item,
                new ArrayList<TodoItem>(),
                getItemsCollection());
        ((ListView) findViewById(R.id.todoList)).setAdapter(_itemAdapter);

        // Set up button listeners
        findViewById(R.id.refresh).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(final View ignored) {
                refreshList();
            }
        });

        findViewById(R.id.clear).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(final View ignored) {
                clearChecked();
            }
        });

        findViewById(R.id.logout).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(final View ignored) {
                _client.getAuth().logout();
            }
        });

        findViewById(R.id.addItem).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(final View ignored) {
                final AlertDialog.Builder diagBuilder = new AlertDialog.Builder(MainActivity.this);

                final LayoutInflater inflater = MainActivity.this.getLayoutInflater();
                final View view = inflater.inflate(R.layout.add_item, null);
                final EditText text = (EditText) view.findViewById(R.id.addItemText);

                diagBuilder.setView(view);
                diagBuilder.setPositiveButton(R.string.addOk, new DialogInterface.OnClickListener() {
                    @Override
                    public void onClick(final DialogInterface dialogInterface, final int i) {
                        addItem(text.getText().toString());
                    }
                });
                diagBuilder.setNegativeButton(R.string.addCancel, new DialogInterface.OnClickListener() {
                    @Override
                    public void onClick(final DialogInterface dialogInterface, final int i) {
                        dialogInterface.cancel();
                    }
                });
                diagBuilder.setCancelable(false);
                diagBuilder.create().show();
            }
        });

        _refresher.run();
    }

    private void addItem(final String text) {
        final Document doc = new Document();
        doc.put("owner_id", _client.getAuth().getUser().getId());
        doc.put("text", text);
        doc.put("checked", false);

        final Task<RemoteInsertOneResult> res = getItemsCollection().insertOne(doc);
        res.addOnCompleteListener(new OnCompleteListener<RemoteInsertOneResult>() {
            @Override
            public void onComplete(@NonNull final Task<RemoteInsertOneResult> task) {
                if (task.isSuccessful()) {
                    refreshList();
                } else {
                    Log.e(TAG, "Error adding item", task.getException());
                }
            }
        });
    }

    private void clearChecked() {
        final Document query = new Document();
        query.put("owner_id", _client.getAuth().getUser().getId());
        query.put("checked", true);

        getItemsCollection().deleteMany(query).addOnCompleteListener(new OnCompleteListener<Document>() {
            @Override
            public void onComplete(@NonNull final Task<Document> task) {
                if (task.isSuccessful()) {
                    refreshList();
                } else {
                    Log.e(TAG, "Error clearing checked items", task.getException());
                }
            }
        });
    }

    private RemoteMongoCollection getItemsCollection() {
        return _mongoClient.getDatabase("todo").getCollection("items");
    }

    private List<TodoItem> convertDocsToTodo(final List<Document> documents) {
        final List<TodoItem> items = new ArrayList<>(documents.size());
        for (final Document doc : documents) {
            items.add(new TodoItem(doc));
        }
        return items;
    }

    private void refreshList() {
        Document filter = new Document("owner_id", _client.getAuth().getUser().getId());
        RemoteFindIterable cursor = getItemsCollection().find(filter).limit(100);
        final ArrayList<Document> documents = new ArrayList<>();
        cursor.into(documents).addOnCompleteListener(new OnCompleteListener() {
            @Override
            public void onComplete(@NonNull Task task) {
                _itemAdapter.clear();
                _itemAdapter.addAll(convertDocsToTodo(documents));
                _itemAdapter.notifyDataSetChanged();
            }
        });
    }

    private void setupLogin() {
        if (_client.getAuth().isLoggedIn()) {
            initTodoView();
            return;
        }

        final String facebookAppId = getString(R.string.facebook_app_id);
        final String googleClientId = getString(R.string.google_client_id);

        setContentView(R.layout.activity_main);

        // If there is a valid Facebook App ID defined in strings.xml, offer Facebook as a login option.
        if (!facebookAppId.equals("TBD")) {
            findViewById(R.id.fb_login_button).setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(final View ignored) {

                    // Check if already logged in
                    if (AccessToken.getCurrentAccessToken() != null) {
                        final FacebookCredential fbCredential = new FacebookCredential(AccessToken.getCurrentAccessToken().getToken());
                        _client.getAuth().loginWithCredential(fbCredential).addOnCompleteListener(new OnCompleteListener<StitchUser>() {
                            @Override
                            public void onComplete(@NonNull final Task<StitchUser> task) {
                                if (task.isSuccessful()) {
                                    initTodoView();
                                } else {
                                    Log.e(TAG, "Error logging in with Facebook", task.getException());
                                }
                            }
                        });
                        return;
                    }

                    _callbackManager = CallbackManager.Factory.create();
                    LoginManager.getInstance().registerCallback(_callbackManager,
                            new FacebookCallback<LoginResult>() {
                                @Override
                                public void onSuccess(LoginResult loginResult) {
                                    final FacebookCredential fbCredential = new FacebookCredential(AccessToken.getCurrentAccessToken().getToken());

                                    _client.getAuth().loginWithCredential(fbCredential).addOnCompleteListener(new OnCompleteListener<StitchUser>() {
                                        @Override
                                        public void onComplete(@NonNull final Task<StitchUser> task) {
                                            if (task.isSuccessful()) {
                                                initTodoView();
                                            } else {
                                                Log.e(TAG, "Error logging in with Facebook", task.getException());
                                            }
                                        }
                                    });
                                }

                                @Override
                                public void onCancel() {}

                                @Override
                                public void onError(final FacebookException exception) {
                                    initTodoView();
                                }
                            });
                    LoginManager.getInstance().logInWithReadPermissions(
                            MainActivity.this,
                            Arrays.asList("public_profile"));
                }
            });
            findViewById(R.id.fb_login_button_frame).setVisibility(View.VISIBLE);
        }

        // If there is a valid Google Client ID defined in strings.xml, offer Google as a login option.
        if (!googleClientId.equals("TBD")) {
            final GoogleSignInOptions.Builder gsoBuilder = new GoogleSignInOptions.Builder(GoogleSignInOptions.DEFAULT_SIGN_IN)
                    .requestServerAuthCode(googleClientId, false);
            final GoogleSignInOptions gso = gsoBuilder.build();

            if (_googleApiClient != null) {
                _googleApiClient.stopAutoManage(MainActivity.this);
                _googleApiClient.disconnect();
            }

            _googleApiClient = new GoogleApiClient.Builder(MainActivity.this)
                    .enableAutoManage(MainActivity.this, new GoogleApiClient.OnConnectionFailedListener() {
                        @Override
                        public void onConnectionFailed(@NonNull ConnectionResult connectionResult) {
                            Log.e(TAG, "Error connecting to google: " + connectionResult.getErrorMessage());
                        }
                    })
                    .addApi(GOOGLE_SIGN_IN_API, gso)
                    .build();

            findViewById(R.id.google_login_button).setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(final View ignored) {
                    final Intent signInIntent =
                            GoogleSignInApi.getSignInIntent(_googleApiClient);
                    startActivityForResult(signInIntent, RC_SIGN_IN);
                }
            });
            findViewById(R.id.google_login_button).setVisibility(View.VISIBLE);
        }

        // Anonymous login
        findViewById(R.id.anonymous_login_button).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(final View ignored) {
                _client.getAuth().loginWithCredential(new AnonymousCredential()).addOnCompleteListener(new OnCompleteListener<StitchUser>() {
                    @Override
                    public void onComplete(@NonNull final Task<StitchUser> task) {
                        if (task.isSuccessful()) {
                            initTodoView();
                        } else {
                            Log.e(TAG, "Error logging in anonymously", task.getException());
                        }
                    }
                });
            }
        });
        findViewById(R.id.anonymous_login_button).setVisibility(View.VISIBLE);
    }
}
