import React from 'react';
import {render} from 'react-dom';
import {StitchClient} from 'stitch';

// These settings should match the ones you've configured in the Stitch admin app.
const APP_ID = "helloworld-fgyjb"
const MONGO_SERVICE_NAME = "mongodb1"
const DB_NAME = "app-fgyjb"
const ITEMS_COLLECTION = "items"
const client = new StitchClient(APP_ID)

const HelloWorld = class extends React.Component {

  constructor(props) {
    super(props);
    this.state = {
      auth: this.props.client.auth(),
      collection: this.props.client.service("mongodb", MONGO_SERVICE_NAME).db(DB_NAME).collection(ITEMS_COLLECTION)
    }
  }

  logout() {
    let x = this.props.client.logout()
    x.then(()=>{
      this.setState({auth: this.props.client.auth()})
    })
  }

  componentDidMount() {
    // After the app loads, get the user's note and put it in the textarea, if they are logged in.
    if(!this.state.auth){
      return 
    }
    this.state.collection.find({owner_id: this.props.client.authedId()})
      .then((data) => {
        if(data.length !== 0){
          this.refs.note.value = data[0].note;
        }
      })
  }

  save() {
    console.log(this);
    this.state.collection.updateOne(
      {owner_id: this.props.client.authedId()}, // query
      {$set:{"note":this.refs.note.value}},     // update modifier
      {upsert: true}                            // perform upsert
    )
  }

  render() {
    if(!this.state.auth){
      // User is not authenticated; display login flow
      return (
        <div>
          <button onClick={() => this.props.client.authWithOAuth("facebook")}>Log in with Facebook</button>
          <button onClick={() => this.props.client.authWithOAuth("google")}>Log in with Google</button>
          <button onClick={() => this.props.client.anonymousAuth(true).then(()=>{window.location.replace("/")})}>Log in anonymously</button>
        </div>
      )
    }

    // User is logged in; display the form.
    const username = (this.state.auth.user.data && this.state.auth.user.data.name) ? this.state.auth.user.data.name : "(unknown)";
    return (
      <div>
        <div>
          <button onClick={() => this.logout()}>log out</button>
        </div>
        <div>Hello, {username}, you are logged in!</div>
        <textarea ref="note" id="note" placeholder="you can save some data here."></textarea>
        <button onClick={() => this.save()}>save</button>
      </div>
    )

  }
}

render((
  <div>
    <HelloWorld client={client}/>
  </div>
), document.getElementById('app'))
