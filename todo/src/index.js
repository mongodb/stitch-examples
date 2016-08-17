import React from 'react';
import ReactDOM from 'react-dom';
import { MongoClient } from 'baas';

let client = new MongoClient("todo", "http://localhost:8080/v1/app/todo_app")

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

var TodoList = React.createClass({
  setItems: function(items){ this.setState({items:items}) },
  loadList: function(){
    let obj = this;
    client.find("items", null, null, function(data){
      obj.setState({items:data.result})
    })
  },

  getInitialState: () => {return {items:[]}},
  componentWillMount: function(){this.loadList()},
  checkHandler: function(id, status){
    client.update("items", {"_id":id}, {$set:{"checked":status}}, false, false, () => {
      this.loadList();
    })
  },

  addItem: function(event){
    if(event.keyCode != 13 ){
      return
    }
    client.insert("items", [{text:event.target.value, "user": {"$oid": client.authedId()}}], () => {
      this.loadList();
    })
  },

  clear: function(){
    client.remove("items", {checked:true}, false, () => {
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

let list = <TodoList items={[]}/>

$(document).ready(() => {
  if (client.auth() == null) {
    $("#login_oauth2_google").prop('disabled', false);
    $("#login_oauth2_google").click(function(e) {
      client.authWithOAuth("google");
    });
    $("#login_oauth2_fb").prop('disabled', false);
    $("#login_oauth2_fb").click(function(e) {
      client.authWithOAuth("facebook");
    });
    return;
  }

  $("#uid").text(`Logged in as ${client.authedId()} via ${client.auth()['provider'].split("/")[1]}`);

  $("#logout").prop('disabled', false);
  $("#logout").click(function(e) {
    client.logout();
  });
  $("#link_oauth2_google").prop('disabled', false);
  $("#link_oauth2_google").click(function(e) {
    client.linkWithOAuth("google");
  });
  $("#link_oauth2_fb").prop('disabled', false);
  $("#link_oauth2_fb").click(function(e) {
    client.linkWithOAuth("facebook");
  });
  ReactDOM.render(list, document.getElementById('app'));
})
