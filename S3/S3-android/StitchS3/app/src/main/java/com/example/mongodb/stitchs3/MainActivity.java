package com.example.mongodb.stitchs3;

import android.net.Uri;
import android.os.AsyncTask;
import android.os.Bundle;
import android.support.annotation.NonNull;
import android.support.v7.app.AppCompatActivity;
import android.util.Base64;
import android.util.Log;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;

import com.google.android.gms.tasks.Continuation;
import com.google.android.gms.tasks.OnCompleteListener;
import com.google.android.gms.tasks.OnFailureListener;
import com.google.android.gms.tasks.OnSuccessListener;
import com.google.android.gms.tasks.Task;

import java.io.BufferedInputStream;
import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.lang.ref.WeakReference;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.ArrayList;
import java.util.Date;
import java.util.Locale;
import java.util.List;
import java.util.Map;
import java.util.HashMap;

// Stitch Client imports
import com.mongodb.stitch.android.StitchClient;
import com.mongodb.stitch.android.PipelineStage;
import com.mongodb.stitch.android.auth.Auth;
import com.mongodb.stitch.android.auth.AvailableAuthProviders;
import com.mongodb.stitch.android.auth.UserProfile;
import com.mongodb.stitch.android.auth.anonymous.AnonymousAuthProvider;

public class MainActivity extends AppCompatActivity {

    // Remember to replace the APP_ID with your Stitch Application ID

    private static final String APP_ID = "<your-app-id>"; // The Stitch Application ID
    private static final String S3_SERVICE_NAME = "Photos";
    private static final String BUCKET_NAME = "<your-bucket>";
    private static final String OBJECT_KEY = "shared-text";
    private static final String TAG = "StitchWhiteboard";

    private EditText _textWidget;
    private Button _saveButton;
    private Button _refreshButton;

    private StitchClient _client;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        _textWidget = (EditText) findViewById(R.id.text);
        _saveButton = (Button) findViewById(R.id.save);
        _refreshButton = (Button) findViewById(R.id.refresh);
        _client = new StitchClient(this, APP_ID);

        Log.i(TAG, "Starting authentication");
        doAnonymousAuthentication();
        fetch();
    }

    public void onClickSave(View view) {
        upload(_textWidget.getText().toString());
    }

    public void onClickRefresh(View view) {
        fetch();
    }

    private void doAnonymousAuthentication() {
        _client.getAuthProviders().continueWithTask(new Continuation<AvailableAuthProviders, Task<Auth>>() {
            @Override
            public Task<Auth> then(@NonNull Task<AvailableAuthProviders> task) throws Exception {
                if (!task.isSuccessful()) {
                    Log.e(TAG, "Could not retrieve authentication providers", task.getException());
                    throw task.getException();
                }

                Log.i(TAG, "Retrieved authentication providers");
                if (!task.getResult().hasAnonymous()) {
                    throw new Exception("Anonymous login not allowed");
                }

                return _client.logInWithProvider(new AnonymousAuthProvider());
            }}).addOnSuccessListener(new OnSuccessListener<Auth>() {
            @Override
            public void onSuccess(@NonNull Auth auth) {
                _client.getUserProfile().addOnCompleteListener(new OnCompleteListener<UserProfile>() {
                    @Override
                    public void onComplete(@NonNull Task<UserProfile> task) {
                        Log.i(TAG, "User Authenticated as " + task.getResult().getId());
                    }
                });

                _refreshButton.setEnabled(true);
                _saveButton.setEnabled(true);
                _textWidget.setEnabled(true);
            }
        }).addOnFailureListener(new OnFailureListener() {
            @Override
            public void onFailure(@NonNull Exception e) {
                Log.e(TAG, "Error logging in anonymously", e);
            }
        });
    }

    private void upload(final String text) {
        final List<PipelineStage> pipeline = new ArrayList<>();

        final Map<String, Object> binaryStage = new HashMap<>();
        binaryStage.put("encoding", "base64");
        binaryStage.put("data", Base64.encodeToString(text.getBytes(), Base64.DEFAULT));
        pipeline.add(new PipelineStage("binary", binaryStage));

        final Map<String, Object> putStage = new HashMap<>();
        putStage.put("bucket", BUCKET_NAME);
        putStage.put("key", OBJECT_KEY);
        putStage.put("acl", "public-read");
        putStage.put("contentType", "text/plain");
        pipeline.add(new PipelineStage("put", S3_SERVICE_NAME, putStage));

        _client.executePipeline(pipeline).addOnCompleteListener(new OnCompleteListener<List<Object>>() {
            @Override
            public void onComplete(@NonNull Task<List<Object>> task) {
                if (!task.isSuccessful()) {
                    Log.e(TAG, "Failed to upload");
                    return;
                }

                Log.i(TAG, "Uploaded");
            }});
    }

    private void fetch() {
        Date date = new Date();
        String encodedBucket = Uri.encode(BUCKET_NAME);
        String urlText = String.format(Locale.US, "https://%s.s3.amazonaws.com/%s?%d", encodedBucket, OBJECT_KEY, date.getTime());

        URL url;
        try {
            url = new URL(urlText);
            FetchTask task = new FetchTask(new WeakReference<>(_textWidget));
            task.execute(url);
        } catch (IOException e) {
            Log.e(TAG, "Failed to fetch", e);
        }
    }
}

class FetchTask extends AsyncTask<URL, Void, String> {
    private IOException e = null;
    private final WeakReference<EditText> _text;

    FetchTask(WeakReference<EditText> editText) {
        _text = editText;
    }

    protected String doInBackground(URL... urls) {
        InputStream inputStream = null;
        StringBuilder builder = new StringBuilder();
        String result = null;

        try {
            HttpURLConnection urlConnection = (HttpURLConnection)urls[0].openConnection();
            inputStream = new BufferedInputStream(urlConnection.getInputStream());
            BufferedReader reader = new BufferedReader(new InputStreamReader(inputStream));
            String inputLine;
            while ((inputLine = reader.readLine()) != null) {
                builder.append(inputLine);
            }
            result = builder.toString();
        } catch (IOException e) {
            this.e = e;
        } finally {
            try {
                if (inputStream != null) {
                    inputStream.close();
                }
            } catch (IOException e) {
                this.e = e;
            }
        }

        return result;
    }

    @Override
    protected void onPostExecute(String s) {
        if (e != null) {
            Log.e("FetchTask", "Failed to fetch message", e);
            return;
        }

        final EditText textWidget = _text.get();
        if (textWidget != null) {
            textWidget.setText(s);
        }
    }
}
