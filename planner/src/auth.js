import React from 'react';

let AuthControls = React.createClass({
  render: function(){
    let client = this.props.client || this.props.route.client;
    let authed = client.auth() != null
    return (
      <div>
        { authed ? <div>Logged in as {client.authedId()} via {client.auth()['provider'].split("/")[1]} </div>: null }
        <button disabled={authed} 
          onClick={() => client.authWithOAuth("google")}>Login with Google</button>
        <button disabled={authed}
          onClick={() => client.authWithOAuth("facebook")}>Login with Facebook</button>
        <button disabled={authed}
          onClick={() => client.linkWithOAuth("google")}>Link with Google</button>
        <button disabled={authed}
          onClick={() => client.linkWithOAuth("facebook")}>Link with Facebook</button>
        <button disabled={!authed} onClick={() => client.logout()}>Logout</button>
      </div>
    )
  },
})

export default AuthControls;

