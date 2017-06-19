package com.mongodb.solomo.activities;

import android.content.Context;
import android.content.Intent;

import com.mongodb.solomo.R;

public class SignInActivity extends SignActivity
{
    public static Intent newIntent(Context context)
    {
        return new Intent(context, SignInActivity.class)
                .setFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP | Intent.FLAG_ACTIVITY_SINGLE_TOP);
    }

    @Override
    protected int getContentView()
    {
        return R.layout.activity_sign_in;
    }

    @Override
    protected void onSignUp()
    {
        startActivity(new Intent(this, SignUpActivity.class));
        finish();
    }

    @Override
    protected void onSignIn()
    {
        // TODO: 12/03/17 sign in with mongoDB
    }
}
