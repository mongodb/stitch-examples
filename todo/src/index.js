import React from 'react';
import ReactDOM from 'react-dom';
import {BaasClient, MongoClient} from 'baas';

let baasClient = new BaasClient("http://localhost:8080/v1/app/todo-app")
let db = new MongoClient(baasClient, "mdb1").getDb("todo")
let items = db.getCollection("items")

function TodoItem({item=null, checkHandler=null}){
  let itemClass = item.checked ? "done" : "";
  return (
    <li>
      <label>
      <input type="checkbox"
        checked={item.checked}
        onChange={ (event) => { checkHandler(item._id, event.target.checked) }}
      />
      <span className={itemClass}>{item.text}</span></label>
    </li>
  )
}

var AuthControls = React.createClass({
  render: function(){
    let authed = this.props.client.auth() != null
    let logout = () => this.props.client.logout()
    return (
      <div>
        { authed ? <div>Logged in as {this.props.client.authedId()} via {baasClient.auth()['provider'].split("/")[1]} </div>: null }
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

var TodoList = React.createClass({
  setItems: function(items){ this.setState({items:items}) },
  loadList: function(){
    let obj = this;
    items.find(null, null, function(data){
      obj.setState({items:data.result})
    })
  },

  getInitialState: () => {return {items:[]}},
  componentWillMount: function(){this.loadList()},
  checkHandler: function(id, status){
    items.update({"_id":id}, {$set:{"checked":status}}, false, false, () => {
      this.loadList();
    }, {"rule": "checked"})
  },

  addItem: function(event){
    if(event.keyCode != 13 ){
      return
    }
    items.insert([{text:event.target.value, "user": {"$oid": baasClient.authedId()}}], () => {
      this.loadList();
    })
  },

  clear: function(){
    items.remove({checked:true}, false, () => {
      this.loadList();
    })
  },

  render: function(){
    return (
      <div>
        <input type="text" placeholder="add a new item..." onKeyDown={this.addItem}/>
        <div>
          <button onClick={this.clear}>Clean up</button>
        </div>
        <ul>
        { 
          this.state.items.length == 0
          ?  <div>list is empty :(</div>
           : this.state.items.map((item) => {
            return <TodoItem key={item._id.$oid} item={item} checkHandler={this.checkHandler}/>;
          }) 
        }
        </ul>
      </div>
    );
  }
})

let list = (
  <div>
    {baasClient.auth() != null ? <TodoList items={[]}/> : null}
    <AuthControls client={baasClient}/>
  </div>
)

$(document).ready(() => {
  ReactDOM.render(list, document.getElementById('app'));
})
