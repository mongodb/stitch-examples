package com.mongodb.stitch.examples.mongocipher;

import android.content.DialogInterface;
import android.support.annotation.NonNull;
import android.support.v7.app.AlertDialog;
import android.support.v7.app.AppCompatActivity;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.widget.Switch;
import android.widget.TextView;

import com.google.android.gms.tasks.Continuation;
import com.google.android.gms.tasks.OnCompleteListener;
import com.google.android.gms.tasks.Task;
import com.mongodb.stitch.android.StitchClient;

import org.apache.commons.lang3.RandomStringUtils;
import org.apache.commons.lang3.StringEscapeUtils;
import org.bson.Document;

// used for authentication and anonymous auth
import com.mongodb.stitch.android.PipelineStage;
import com.mongodb.stitch.android.auth.Auth;
import com.mongodb.stitch.android.auth.AvailableAuthProviders;
import com.mongodb.stitch.android.auth.anonymous.AnonymousAuthProvider;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class MainActivity extends AppCompatActivity {

    private static final String APP_ID = "STITCH-APP-ID";
    private static String TAG = "STITCH";
    private static final String HTTP_SERVICE_NAME = "STITCH-HTTP-SERVICE";
    private static final String HTTP_SERVICE_ACTION = "post";
    private static final String STITCH_SERVICE_ACTION = "expr";

    private StitchClient _client;

    @Override
    protected void onCreate(final Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        _client = new StitchClient(this, APP_ID);

        doAnonymousAuthentication();
    }

    public void cipher(View view){

        if (!_client.isAuthenticated()){
            warnAuth();
            return;
        }

        String msg, key;

        TextView messageInput = (TextView) findViewById(R.id.message);
        if (messageInput.getText().toString().equalsIgnoreCase("")){
            warnEmptyInput();
            return;
        } else {
            msg = StringEscapeUtils.unescapeJava(messageInput.getText().toString());
        }

        TextView keyInput = (TextView) findViewById(R.id.key);
        key = generateKey(msg);
        keyInput.setText("Secret Key: " + key);

        Switch s = (Switch) findViewById(R.id.switchPipeline);
        if (!s.isChecked()){
            executeLambdaWithHTTPService(msg,key, "cipher");
        } else {
            executeLambdaWithNamedPipeline(msg,key, "cipher");
        }
    }

    public void decipher(View view){

        if (!_client.isAuthenticated()){
            warnAuth();
            return;
        }

        String msg, key;

        TextView messageInput = (TextView) findViewById(R.id.decryptMessage);
        if (messageInput.getText().toString().equalsIgnoreCase("")){
            warnEmptyInput();
            return;
        } else {
            msg = StringEscapeUtils.unescapeJava(messageInput.getText().toString());
        }

        TextView keyInput = (TextView) findViewById(R.id.decryptKey);
        if (keyInput.getText().toString().equalsIgnoreCase("")){
            warnEmptyInput();
            return;
        } else {
            key = keyInput.getText().toString();
        }

        if (msg.length() != key.length()){
            warnCipherKeyMismatch();
            return;
        }

        Switch s = (Switch) findViewById(R.id.switchPipeline);
        if (!s.isChecked()){
            executeLambdaWithHTTPService(msg,key, "decipher");
        } else {
            executeLambdaWithNamedPipeline(msg,key, "decipher");
        }
    }

    public void executeLambdaWithHTTPService(final String msg,final String key,final String cipherDecipher){

        final Map<String, Object> cipher = new HashMap<>();
        // The Amazon API Gateway URL endpoint should link to your AWS Lambda function
        cipher.put("url" , "<AMAZON API GATEWAY URL ENDPOINT>" );

        final Map<String,Object> args = new HashMap<>();
        args.put("message",msg);
        args.put("key",key);

        cipher.put("body",args);

        final PipelineStage pipeline = new PipelineStage(HTTP_SERVICE_ACTION,HTTP_SERVICE_NAME,cipher);

        _client.executePipeline(pipeline).addOnCompleteListener(new OnCompleteListener<List<Object>>() {
            @Override
            public void onComplete(@NonNull Task<List<Object>> task) {
                if (!task.isSuccessful()){
                    Log.e(TAG, "Failed to execute pipeline: " + task.getException());
                } else {

                    TextView tv;
                    if (cipherDecipher.equalsIgnoreCase("cipher")){
                        tv = (TextView) findViewById(R.id.cipheredMessage);
                    } else if (cipherDecipher.equalsIgnoreCase("decipher")){
                        tv =  (TextView) findViewById(R.id.decipheredMessage);
                    } else {
                        Log.e(TAG, "Reached impossible case");
                        return;
                    }

                    Document result;
                    if (task.getResult().equals(null)){
                        result = new Document("body","");
                    } else {
                        result = (Document) task.getResult().get(0);
                    }

                    String res = result.get("body").toString();
                    tv.setText("Message:" + res);
                }
            }
        });
    }

    public void executeLambdaWithNamedPipeline(final String msg,final String key,final String cipherDecipher){
        final Map<String, Object> expression = new HashMap<>();

        final Map<String, Object> cipher = new HashMap<>();

        final Map<String, Object> pipe = new HashMap<>();
        pipe.put("name", "AWSLambda");

        final Map<String, Object> args = new HashMap<>();
        args.put("message",msg);
        args.put("key",key);
        pipe.put("args",args);

        cipher.put("$pipeline",pipe);
        expression.put("expression", cipher);

        final PipelineStage pipeline = new PipelineStage(STITCH_SERVICE_ACTION, expression);

        _client.executePipeline(pipeline).continueWith(new Continuation<List<Object>, Object>() {
            @Override
            public Object then(@NonNull Task<List<Object>> task) throws Exception {
                if (!task.isSuccessful()){
                    Log.e(TAG, "Failed to execute pipeline: " + task.getException());
                } else {
                    TextView tv;
                    if (cipherDecipher.equalsIgnoreCase("cipher")){
                        tv = (TextView) findViewById(R.id.cipheredMessage);
                    } else if (cipherDecipher.equalsIgnoreCase("decipher")){
                        tv =  (TextView) findViewById(R.id.decipheredMessage);
                    } else {
                        Log.e(TAG, "Reached impossible case");
                        return null;
                    }
                    Document result = (Document) task.getResult().get(0);

                    String res = result.get("body").toString();
                    tv.setText("Message: " + res);
                }
                return null;
            }
        });
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
                                    Log.e(TAG, "Error logging in anonymously: ", task.getException());
                                }
                                return null;
                            }
                        });
                    }
                }
            }
        });
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

    private void warnEmptyInput() {
        new AlertDialog.Builder(this)
                .setTitle("Empty Input")
                .setMessage("Please enter an alphanumeric string of at least one character.")
                .setPositiveButton(android.R.string.yes, new DialogInterface.OnClickListener() {
                    public void onClick(DialogInterface dialog, int which) {
                    }
                })
                .setIcon(android.R.drawable.ic_dialog_alert)
                .show();
        return;
    }

    private void warnCipherKeyMismatch() {
        new AlertDialog.Builder(this)
                .setTitle("Cipher Key Mismatch!")
                .setMessage("The cipher key entered must be the same length as the message. Are you sure you copied the cipher key correctly?")
                .setPositiveButton(android.R.string.yes, new DialogInterface.OnClickListener() {
                    public void onClick(DialogInterface dialog, int which) {
                    }
                })
                .setIcon(android.R.drawable.ic_dialog_alert)
                .show();
        return;
    }

    private String generateKey(String msg){

        String key = "";

        for (int i=0;i<msg.length(); i++){
            key = key + RandomStringUtils.randomAlphanumeric(1);
        }

        return key;
    }

}
