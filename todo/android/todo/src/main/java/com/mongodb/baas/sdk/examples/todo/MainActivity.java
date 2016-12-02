package com.mongodb.baas.sdk.examples.todo;

import android.app.AlertDialog;
import android.content.DialogInterface;
import android.content.Intent;
import android.os.Handler;
import android.support.annotation.NonNull;
import android.support.v7.app.AppCompatActivity;
import android.os.Bundle;
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
import com.facebook.login.widget.LoginButton;
import com.google.android.gms.tasks.Continuation;
import com.google.android.gms.tasks.OnCompleteListener;
import com.google.android.gms.tasks.OnSuccessListener;
import com.google.android.gms.tasks.Task;
import com.google.android.gms.tasks.TaskCompletionSource;
import com.google.android.gms.tasks.Tasks;
import com.mongodb.baas.sdk.BaasClient;
import com.mongodb.baas.sdk.auth.Auth;
import com.mongodb.baas.sdk.auth.AuthProviderInfo;
import com.mongodb.baas.sdk.auth.facebook.FacebookAuthProvider;
import com.mongodb.baas.sdk.auth.facebook.FacebookAuthProviderInfo;
import com.mongodb.baas.sdk.services.mongodb.MongoClient;

import org.bson.Document;

import java.lang.ref.WeakReference;
import java.util.ArrayList;
import java.util.List;

import static com.mongodb.baas.sdk.services.mongodb.MongoClient.*;

public class MainActivity extends AppCompatActivity {

    private static final String TAG = "TodoApp";
    private static final String APP_NAME = "todo";
    private static final long REFRESH_INTERVAL_MILLIS = 1000;

    private CallbackManager _callbackManager;
    private BaasClient _client;
    private MongoClient _mongoClient;

    private TodoListAdapter _itemAdapter;
    private Handler _handler;
    private Runnable _refresher;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        _handler = new Handler();
        _refresher = new ListRefresher(this);

        _client = new BaasClient(this, APP_NAME, "http://erd.ngrok.io");
        initLogin();
    }

    private static class ListRefresher implements Runnable {

        private WeakReference<MainActivity> _main;

        public ListRefresher(final MainActivity activity) {
            _main = new WeakReference<>(activity);
        }

        @Override
        public void run() {
            final MainActivity activity = _main.get();
            if (activity != null) {
                activity.refreshList().addOnCompleteListener(new OnCompleteListener<Void>() {
                    @Override
                    public void onComplete(@NonNull final Task<Void> ignored) {
                        activity._handler.postDelayed(ListRefresher.this, REFRESH_INTERVAL_MILLIS);
                    }
                });
            }
        }
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (_callbackManager != null) {
            _callbackManager.onActivityResult(requestCode, resultCode, data);
            return;
        }
        Log.e(TAG, "Nowhere to send activity result for ourselves");
    }

    private void initLogin() {
        _client.getAuthProviders().continueWithTask(new Continuation<AuthProviderInfo, Task<Void>>() {
            @Override
            public Task<Void> then(@NonNull final Task<AuthProviderInfo> task) throws Exception {
                if (task.isSuccessful()) {
                    if (task.getResult().hasFacebook()) {
                        return logInToFacebook(task.getResult().getFacebook());
                    }
                    return Tasks.forResult(null);
                } else {
                    return Tasks.forException(task.getException());
                }
            }
        }).addOnCompleteListener(new OnCompleteListener<Void>() {
            @Override
            public void onComplete(@NonNull final Task<Void> task) {
                if (task.isSuccessful()) {
                    _mongoClient = new MongoClient(_client, "mdb1");
                    initTodoView();
                } else {
                    Log.e(TAG, "Error getting auth provider info", task.getException());
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
                _client.logout().addOnSuccessListener(new OnSuccessListener<Void>() {
                    @Override
                    public void onSuccess(final Void ignored) {
                        LoginManager.getInstance().logOut();
                        _handler.removeCallbacks(_refresher);
                        initLogin();
                    }
                });
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
        doc.put("user", _client.getAuth().getUser().getId());
        doc.put("text", text);

        getItemsCollection().insertOne(doc).addOnCompleteListener(new OnCompleteListener<Void>() {
            @Override
            public void onComplete(@NonNull final Task<Void> task) {
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
        query.put("user", _client.getAuth().getUser().getId());
        query.put("checked", true);

        getItemsCollection().deleteMany(query).addOnCompleteListener(new OnCompleteListener<Void>() {
            @Override
            public void onComplete(@NonNull final Task<Void> task) {
                if (task.isSuccessful()) {
                    refreshList();
                } else {
                    Log.e(TAG, "Error clearing checked items", task.getException());
                }
            }
        });
    }

    private Collection getItemsCollection() {
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
        return getItemsCollection().findMany().continueWithTask(new Continuation<List<Document>, Task<Void>>() {
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

    private Task<Void> logInToFacebook(final FacebookAuthProviderInfo fbAuthProv) {

        final TaskCompletionSource<Void> future = new TaskCompletionSource<>();
        FacebookSdk.setApplicationId(fbAuthProv.getApplicationId());

        final TaskCompletionSource<Void> initFuture = new TaskCompletionSource<>();
        FacebookSdk.sdkInitialize(getApplicationContext(), new FacebookSdk.InitializeCallback() {
            @Override
            public void onInitialized() {
                initFuture.setResult(null);
            }
        });
        initFuture.getTask().addOnSuccessListener(new OnSuccessListener<Void>() {
            @Override
            public void onSuccess(final Void ignored) {
                if (AccessToken.getCurrentAccessToken() != null) {
                    final FacebookAuthProvider fbProvider =
                            FacebookAuthProvider.fromAccessToken(AccessToken.getCurrentAccessToken().getToken());
                    _client.logInWithProvider(fbProvider).addOnCompleteListener(new OnCompleteListener<Auth>() {
                        @Override
                        public void onComplete(@NonNull final Task<Auth> task) {
                            if (task.isSuccessful()) {
                                future.setResult(null);
                            } else {
                                Log.e(TAG, "Error logging in with Facebook", task.getException());
                                future.setException(task.getException());
                            }
                        }
                    });
                    return;
                }

                setContentView(R.layout.activity_main);

                final LoginButton loginButton = (LoginButton) findViewById(R.id.login_button);
                loginButton.setReadPermissions(fbAuthProv.getScopes());

                _callbackManager = CallbackManager.Factory.create();
                LoginManager.getInstance().registerCallback(_callbackManager,
                        new FacebookCallback<LoginResult>() {
                            @Override
                            public void onSuccess(LoginResult loginResult) {
                                final FacebookAuthProvider fbProvider =
                                        FacebookAuthProvider.fromAccessToken(loginResult.getAccessToken().getToken());

                                _client.logInWithProvider(fbProvider).addOnCompleteListener(new OnCompleteListener<Auth>() {
                                    @Override
                                    public void onComplete(@NonNull final Task<Auth> task) {
                                        if (task.isSuccessful()) {
                                            future.setResult(null);
                                        } else {
                                            Log.e(TAG, "Error logging in with Facebook", task.getException());
                                            future.setException(task.getException());
                                        }
                                    }
                                });
                            }

                            @Override
                            public void onCancel() {
                                future.setResult(null);
                            }

                            @Override
                            public void onError(final FacebookException exception) {
                                future.setException(exception);
                            }
                        });
            }
        });

        return future.getTask();
    }
}
