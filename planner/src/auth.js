import React from 'react';

let AuthControls = React.createClass({
  render: function(){
    let authed = this.props.client.auth() != null
    let logout = () => this.props.client.logout()
    return (
      <div>
        { authed ? <div>Logged in as {this.props.client.authedId()} via {this.props.client.auth()['provider'].split("/")[1]} </div>: null }
        <button disabled={authed} 
          onClick={() => this.props.client.authWithOAuth("google")}>Login with Google</button>
        <button disabled={authed}
          onClick={() => this.props.client.authWithOAuth("facebook")}>Login with Facebook</button>
        <button disabled={authed}
          onClick={() => this.props.client.linkWithOAuth("google")}>Link with Google</button>
        <button disabled={authed}
          onClick={() => this.props.client.linkWithOAuth("facebook")}>Link with Facebook</button>
        <button disabled={!authed} onClick={() => this.props.client.logout()}>Logout</button>
      </div>
    )
  },
})

export default AuthControls;

