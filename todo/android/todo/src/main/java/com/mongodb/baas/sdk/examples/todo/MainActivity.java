package com.mongodb.baas.sdk.examples.todo;

import android.content.Intent;
import android.support.annotation.NonNull;
import android.support.v7.app.AppCompatActivity;
import android.os.Bundle;
import android.util.Log;

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
import com.mongodb.baas.sdk.BaaSClient;
import com.mongodb.baas.sdk.auth.Auth;
import com.mongodb.baas.sdk.auth.AuthProviderInfo;
import com.mongodb.baas.sdk.auth.facebook.FacebookAuthProvider;
import com.mongodb.baas.sdk.auth.facebook.FacebookAuthProviderInfo;
import com.mongodb.baas.sdk.services.mongodb.MongoClient;

import org.bson.Document;

import java.util.List;

public class MainActivity extends AppCompatActivity {

    private CallbackManager _callbackManager;
    private BaaSClient _client;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        _client = new BaaSClient(this, "todo", "http://erd.ngrok.io");
        _client.getAuthProviders().continueWithTask(new Continuation<AuthProviderInfo, Task<Void>>() {
            @Override
            public Task<Void> then(@NonNull Task<AuthProviderInfo> task) throws Exception {
                if (task.isSuccessful()) {
                    if (task.getResult().hasFacebook()) {
                        return logInToFacebook(task.getResult().getFacebook());
                    }
                    return Tasks.forResult(null);
                } else {
                    throw task.getException();
                }
            }
        }).addOnSuccessListener(new OnSuccessListener<Void>() {
            @Override
            public void onSuccess(Void aVoid) {
                final MongoClient mongoClient = new MongoClient(_client, "mdb1");
                mongoClient.getDatabase("todo").getCollection("items").findMany().addOnCompleteListener(new OnCompleteListener<List<Document>>() {
                    @Override
                    public void onComplete(@NonNull Task<List<Document>> task) {
                        if (task.isSuccessful()) {
                            final List<Document> documents = task.getResult();
                            System.out.println("Fetched " + documents.size() + " docs");
                            for (final Document doc : documents) {
                                System.out.println(doc);
                            }
                        } else {
                            task.getException().printStackTrace();
                        }
                    }
                });
            }
        });
    }

    private Task<Void> logInToFacebook(final FacebookAuthProviderInfo fbAuthProv) {

        FacebookSdk.setApplicationId(fbAuthProv.getApplicationId());
        FacebookSdk.sdkInitialize(getApplicationContext());

        if (AccessToken.getCurrentAccessToken() != null) {
            Log.d("Todo", "Already logged in: " + AccessToken.getCurrentAccessToken().getToken());
        }

        setContentView(R.layout.activity_main);

        final LoginButton loginButton = (LoginButton) findViewById(R.id.login_button);
        loginButton.setReadPermissions(fbAuthProv.getScopes());

        final TaskCompletionSource<Void> future = new TaskCompletionSource<>();

        _callbackManager = CallbackManager.Factory.create();
        LoginManager.getInstance().registerCallback(_callbackManager,
                new FacebookCallback<LoginResult>() {
                    @Override
                    public void onSuccess(LoginResult loginResult) {
                        final FacebookAuthProvider fbProvider =
                                FacebookAuthProvider.fromAccessToken(loginResult.getAccessToken().getToken());
                        _client.logInWithProvider(fbProvider).addOnSuccessListener(new OnSuccessListener<Auth>() {
                            @Override
                            public void onSuccess(Auth auth) {
                                future.setResult(null);
                            }
                        });
                    }

                    @Override
                    public void onCancel() {
                        future.setResult(null);
                    }

                    @Override
                    public void onError(FacebookException exception) {
                        future.setException(exception);
                    }
                });

        return future.getTask();
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        _callbackManager.onActivityResult(requestCode, resultCode, data);
    }
}
