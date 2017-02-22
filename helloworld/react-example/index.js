import React from 'react';
import {render} from 'react-dom';
import {BaasClient, MongoClient} from 'baas';

// These settings should match the ones you've configured in the BaaS admin app.
const APP_ID = "helloworld-iiqqs"
const MONGO_SERVICE_NAME = "mdb1"
const DB_NAME = "my_db"
const ITEMS_COLLECTION = "items"
const client = new BaasClient(APP_ID)

const HelloWorld = React.createClass({
  getInitialState(){
    return {
      auth: this.props.client.auth(),
      collection: new MongoClient(this.props.client, MONGO_SERVICE_NAME).getDb(DB_NAME).getCollection(ITEMS_COLLECTION)
    }
  },
  logout(){
    let x = this.props.client.logout()
    x.then(()=>{
      this.setState({auth: this.props.client.auth()})
    })
  },
  componentDidMount(){
    // After the app loads, get the user's note and put it in the textarea, if they are logged in.
    if(!this.state.auth){
      return 
    }
    this.state.collection.find({owner_id: this.props.client.authedId()}, {})
      .then((data)=>{
        if(data.result.length !== 0){
          this.refs.note.value = data.result[0].note
        }
      })
  },
  save(){
    this.state.collection.upsert(
      {owner_id: this.props.client.authedId()}, // query
      {$set:{"note":this.refs.note.value}}      // update modifier
    )
  },
  render(){
    if(!this.state.auth){
      // User is not authenticated: display login flow
      return (
        <div>
          <button onClick={()=>{this.props.client.authWithOAuth("facebook")}}>Log in with Facebook</button>
          <button onClick={()=>{this.props.client.authWithOAuth("google")}}>Log in with Google</button>
        </div>
      )
    }

    // User is logged in - display the form.
    const username = (this.state.auth.user.data && this.state.auth.user.data.name)  ? this.state.auth.user.data.name : "(unknown)"
    return (
      <div>
        <div>
          <button onClick={this.logout}>log out</button>
        </div>
        <div>Hello, {username}, you are logged in!</div>
        <textarea ref="note" id="note" placeholder="you can save some data here."></textarea>
        <button onClick={this.save}>save</button>
      </div>
    )

  }
})

render((
  <div>
    <HelloWorld client={client}/>
  </div>
), document.getElementById('app'))
