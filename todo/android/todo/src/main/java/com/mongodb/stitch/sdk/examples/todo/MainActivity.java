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
import com.facebook.FacebookSdk;
import com.facebook.login.LoginManager;
import com.facebook.login.LoginResult;
import com.google.android.gms.auth.api.signin.GoogleSignInOptions;
import com.google.android.gms.auth.api.signin.GoogleSignInResult;
import com.google.android.gms.common.ConnectionResult;
import com.google.android.gms.common.api.GoogleApiClient;
import com.google.android.gms.common.api.ResultCallback;
import com.google.android.gms.common.api.Status;
import com.google.android.gms.tasks.Continuation;
import com.google.android.gms.tasks.OnCompleteListener;
import com.google.android.gms.tasks.OnSuccessListener;
import com.google.android.gms.tasks.Task;
import com.google.android.gms.tasks.TaskCompletionSource;
import com.google.android.gms.tasks.Tasks;
import com.mongodb.stitch.android.AuthListener;
import com.mongodb.stitch.android.StitchClient;
import com.mongodb.stitch.android.auth.AvailableAuthProviders;
import com.mongodb.stitch.android.auth.anonymous.AnonymousAuthProvider;
import com.mongodb.stitch.android.auth.oauth2.facebook.FacebookAuthProvider;
import com.mongodb.stitch.android.auth.oauth2.google.GoogleAuthProvider;
import com.mongodb.stitch.android.services.mongodb.MongoClient;

import org.bson.Document;

import java.lang.ref.WeakReference;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import static com.google.android.gms.auth.api.Auth.GOOGLE_SIGN_IN_API;
import static com.google.android.gms.auth.api.Auth.GoogleSignInApi;

public class MainActivity extends AppCompatActivity implements StitchClientListener {

    private static final String TAG = "TodoApp";
    private static final long REFRESH_INTERVAL_MILLIS = 1000;
    private static final int RC_SIGN_IN = 421;

    private CallbackManager _callbackManager;
    private GoogleApiClient _googleApiClient;
    private StitchClient _client;
    private MongoClient _mongoClient;

    private TodoListAdapter _itemAdapter;
    private Handler _handler;
    private Runnable _refresher;

    private boolean _fbInitOnce;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        _handler = new Handler();
        _refresher = new ListRefresher(this);

        StitchClientManager.initialize(this.getApplicationContext());
        StitchClientManager.registerListener(this);
    }

    @Override
    public void onReady(StitchClient stitchClient) {
        this._client = stitchClient;
        this._client.addAuthListener(new MyAuthListener(this));

        _mongoClient = new MongoClient(_client, "mongodb-atlas");
        initLogin();
    }

    private static class MyAuthListener implements AuthListener {

        private WeakReference<MainActivity> _main;

        public MyAuthListener(final MainActivity activity) {
            _main = new WeakReference<>(activity);
        }

        @Override
        public void onLogin() {
            Log.d(TAG, "Logged into Stitch");
        }

        @Override
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
                        activity.initLogin();
                    }
                });
            }
        }
    }

    private static class ListRefresher implements Runnable {

        private WeakReference<MainActivity> _main;

        public ListRefresher(final MainActivity activity) {
            _main = new WeakReference<>(activity);
        }

        @Override
        public void run() {
            final MainActivity activity = _main.get();
            if (activity != null && activity._client.isAuthenticated()) {
                activity.refreshList().addOnCompleteListener(new OnCompleteListener<Void>() {
                    @Override
                    public void onComplete(@NonNull final Task<Void> task) {
                        if (!task.isSuccessful()) {
                            Log.e(TAG, "Error refreshing list. Stopping auto refresh", task.getException());
                            return;
                        }
                        activity._handler.postDelayed(ListRefresher.this, REFRESH_INTERVAL_MILLIS);
                    }
                });
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
            final GoogleAuthProvider googleProvider =
                    GoogleAuthProvider.fromAuthCode(result.getSignInAccount().getServerAuthCode());
            _client.logInWithProvider(googleProvider).addOnCompleteListener(new OnCompleteListener<String>() {
                @Override
                public void onComplete(@NonNull final Task<String> task) {
                    if (task.isSuccessful()) {
                        initTodoView();
                    } else {
                        Log.e(TAG, "Error logging in with Google", task.getException());
                    }
                }
            });
        }
    }

    private void initLogin() {
        this._client.getAuthProviders().addOnCompleteListener(new OnCompleteListener<AvailableAuthProviders>() {
            @Override
            public void onComplete(Task<AvailableAuthProviders> task) {
                if (task.isSuccessful()) {
                    setupLogin(task.getResult());
                } else {
                    Log.e(TAG, "Error getting auth info", task.getException());
                    // Maybe retry here...
                }
            }
        });
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
                _client.logout();
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
        doc.put("owner_id", _client.getUserId());
        doc.put("text", text);
        doc.put("checked", false);

        getItemsCollection().insertOne(doc).addOnCompleteListener(new OnCompleteListener<Document>() {
            @Override
            public void onComplete(@NonNull final Task<Document> task) {
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
        query.put("owner_id", _client.getUserId());
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

    private MongoClient.Collection getItemsCollection() {
        return _mongoClient.getDatabase("todo").getCollection("items");
    }

    private List<TodoItem> convertDocsToTodo(final List<Document> documents) {
        final List<TodoItem> items = new ArrayList<>(documents.size());
        for (final Document doc : documents) {
            items.add(new TodoItem(doc));
        }
        return items;
    }

    private Task<Void> refreshList() {
        return getItemsCollection().find(new Document("owner_id", _client.getUserId()), 100).continueWithTask(new Continuation<List<Document>, Task<Void>>() {
            @Override
            public Task<Void> then(@NonNull final Task<List<Document>> task) throws Exception {
                if (task.isSuccessful()) {
                    final List<Document> documents = task.getResult();
                    _itemAdapter.clear();
                    _itemAdapter.addAll(convertDocsToTodo(documents));
                    _itemAdapter.notifyDataSetChanged();
                    return Tasks.forResult(null);
                } else {
                    Log.e(TAG, "Error refreshing list", task.getException());
                    return Tasks.forException(task.getException());
                }
            }
        });
    }

    private void setupLogin(final AvailableAuthProviders info) {

        if (_client.isAuthenticated()) {
            initTodoView();
            return;
        }

        final List<Task<Void>> initFutures = new ArrayList<>();

        if (info.hasFacebook()) {
            FacebookSdk.setApplicationId(info.getFacebook().getConfig().getClientId());
            final TaskCompletionSource<Void> fbInitFuture = new TaskCompletionSource<>();
            FacebookSdk.sdkInitialize(getApplicationContext(), new FacebookSdk.InitializeCallback() {
                @Override
                public void onInitialized() {
                    _fbInitOnce = true;
                    fbInitFuture.setResult(null);
                }
            });
            initFutures.add(fbInitFuture.getTask());
        } else {
            FacebookSdk.setApplicationId("INVALID");
            final TaskCompletionSource<Void> fbInitFuture = new TaskCompletionSource<>();
            FacebookSdk.sdkInitialize(getApplicationContext(), new FacebookSdk.InitializeCallback() {
                @Override
                public void onInitialized() {
                    fbInitFuture.setResult(null);
                }
            });
            initFutures.add(fbInitFuture.getTask());
        }

        Tasks.whenAll(initFutures).addOnSuccessListener(new OnSuccessListener<Void>() {
            @Override
            public void onSuccess(final Void ignored) {
                setContentView(R.layout.activity_main);

                if (info.hasFacebook()) {
                    findViewById(R.id.fb_login_button).setOnClickListener(new View.OnClickListener() {
                        @Override
                        public void onClick(final View ignored) {

                            // Check if already logged in
                            if (AccessToken.getCurrentAccessToken() != null) {
                                final FacebookAuthProvider fbProvider =
                                        FacebookAuthProvider.fromAccessToken(AccessToken.getCurrentAccessToken().getToken());
                                _client.logInWithProvider(fbProvider).addOnCompleteListener(new OnCompleteListener<String>() {
                                    @Override
                                    public void onComplete(@NonNull final Task<String> task) {
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
                                            final FacebookAuthProvider fbProvider =
                                                    FacebookAuthProvider.fromAccessToken(loginResult.getAccessToken().getToken());

                                            _client.logInWithProvider(fbProvider).addOnCompleteListener(new OnCompleteListener<String>() {
                                                @Override
                                                public void onComplete(@NonNull final Task<String> task) {
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

                if (info.hasGoogle()) {
                    final GoogleSignInOptions.Builder gsoBuilder = new GoogleSignInOptions.Builder(GoogleSignInOptions.DEFAULT_SIGN_IN)
                            .requestServerAuthCode(info.getGoogle().getConfig().getClientId(), false);
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

                if (info.hasAnonymous()) {
                    findViewById(R.id.anonymous_login_button).setOnClickListener(new View.OnClickListener() {
                        @Override
                        public void onClick(final View ignored) {
                            _client.logInWithProvider(new AnonymousAuthProvider()).addOnCompleteListener(new OnCompleteListener<String>() {
                                @Override
                                public void onComplete(@NonNull final Task<String> task) {
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
        });
    }
}

