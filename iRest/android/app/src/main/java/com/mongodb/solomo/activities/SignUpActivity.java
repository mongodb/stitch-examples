package com.mongodb.solomo.activities;

import com.mongodb.solomo.R;


public class SignUpActivity extends SignActivity
{

    @Override
    protected int getContentView()
    {
        return R.layout.activity_sign_up;
    }

    @Override
    protected void onSignUp()
    {
        // TODO: 12/03/17 sign up MongoDB
    }

    @Override
    protected void onSignIn()
    {
        startActivity(SignInActivity.newIntent(this));
        finish();
    }
}
