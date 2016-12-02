import React from 'react';
import {render} from 'react-dom';
import {BaasClient, MongoClient} from 'baas';
import {browserHistory, Router, Route , Link} from 'react-router'

require("../static/todo.scss")

let baasClient = new BaasClient("http://localhost:8080/v1/app/todo")
let db = new MongoClient(baasClient, "mdb1").getDb("todo")
let items = db.getCollection("items")
let users = db.getCollection("users")

let TodoItem = React.createClass({
	clicked(){
    items.updateOne({"_id":this.props.item._id}, {$set:{"checked":!this.props.item.checked}})
		.then(this.props.onChange)
	},
	render(){
	console.log(this.props)
		let itemClass = this.props.item.checked ? "done" : "";
		return (
			<div className="todo-item-root">
				<label className="todo-item-container">
					<div className={"checkbox-input " + itemClass} onClick={this.clicked}>
						{this.props.item.checked ? "✓" : null}
					</div>
					<span className={"todo-item-text " + itemClass}>{this.props.item.text}</span>
				</label>
			</div>
		)
	}
})
/*
function TodoItem({item=null, checkHandler=null}){
}
*/

var AuthControls = React.createClass({
  render: function(){
    let authed = this.props.client.auth() != null
    let logout = () => this.props.client.logout()
    return (
      <div>
        { authed ? <div>Logged in via {baasClient.auth()['provider'].split("/")[1]} </div>: null }
				{	!authed ? 
					<div>
						<button onClick={() => this.props.client.authWithOAuth("google")}>Login with Google</button>
						<button onClick={() => this.props.client.authWithOAuth("facebook")}>Login with Facebook</button>
					</div>
					: null
				}
        <button disabled={!authed} onClick={() => this.props.client.logout()}>Logout</button>
      </div>
    )
        //<button disabled={authed}
          //onClick={() => this.props.client.linkWithOAuth("google")}>Link with Google</button>
        //<button disabled={authed}
          //onClick={() => this.props.client.linkWithOAuth("facebook")}>Link with Facebook</button>
  },
})

var TodoList = React.createClass({
  loadList: function(){
    let authed = baasClient.auth() != null
    if(!authed){
      return
    }
    let obj = this;
    items.find(null, null).then(function(data){
      obj.setState({items:data.result})
    })
  },

  getInitialState: () => {return {items:[]}},
  componentWillMount: function(){this.loadList()},
  checkHandler: function(id, status){
    items.updateOne({"_id":id}, {$set:{"checked":status}}).then(() => {
      this.loadList();
    }, {"rule": "checked"})
  },

  addItem: function(event){
    if(event.keyCode != 13 ){
      return
    }
    items.insert([{text:event.target.value, "user": {"$oid": baasClient.authedId()}}]).then(
      () => {
        this._newitem.value = ""
        this.loadList();
      }
    )
  },

  clear: function(){
    items.deleteMany({checked:true}).then(() => {
      this.loadList();
    })
  },

  render: function(){
    let loggedInResult = 
      (<div>
        <button onClick={this.clear}>Clean up</button>
        <ul>
        <input type="text" className="new-item" placeholder="add a new item..." ref={ (n)=>{this._newitem=n} } onKeyDown={this.addItem}/>
        { 
          this.state.items.length == 0
          ?  <div>list is empty.</div>
           : this.state.items.map((item) => {
            return <TodoItem key={item._id.$oid} item={item} onChange={this.loadList}/>;
          }) 
        }
        </ul>
      </div>);
    return baasClient.auth() == null ? null : loggedInResult;
  }
})

var Home = function(){
  let authed = baasClient.auth() != null
  return (
    <div>
      {authed ? <Link to="/settings" className="settings-link">Settings</Link> : null}
      <div>
        <TodoList/>
        <AuthControls client={baasClient}/>
      </div>
    </div>
  )
}

function initUserInfo(id){
  users.upsert(
    {'_id': {"$oid":baasClient.authedId()}},
    {$setOnInsert:{"phone_number":"", "number_status":"unverified"}},
    true, false).then(function(){});
}

var AwaitVerifyCode = React.createClass({
  checkCode: function(e){
    let obj = this
    if(e.keyCode == 13){
      users.updateOne(
        {_id:{"$oid":baasClient.authedId()}, verify_code:this._code.value},
        {"$set":{"number_status":"verified"}}).then(
          (data)=>{ obj.props.onSubmit() }
        )
    }
  },
  render: function(){
    return (
      <div>
        <h3>Enter the code that you received via text:</h3>
        <input type="textbox" name="code" ref={(n)=>{this._code=n}} placeholder="verify code" onKeyDown={this.checkCode}/>
      </div>
    )
  }
})

let formatPhoneNum  = (raw)=>{
  return raw.replace(/\D/g, "")
}

let generateCode = (len) => {
    let text = "";
    let digits = "0123456789"
    for(var i=0;i<len;i++){
      text+=digits.charAt(Math.floor(Math.random() * digits.length));
    }
    return text
}

var NumberConfirm = React.createClass({
  saveNumber: function(e){
    if(e.keyCode == 13){
      if(formatPhoneNum(this._number.value).length == 10){
        // TODO: generate this code on the server-side.
        let code = generateCode(7)
        baasClient.executePipeline([
          {action:"literal", args:{items:[{name:"hi"}]}},
          {
            service:"tw1", action:"send", 
            args: {
              "to":"+1" + this._number.value,
              "from":"$$var.ourNumber",
              "body": "Your confirmation code is "+ code
            }
          }]).then(
          (data)=>{
            users.updateOne(
              {"_id": {"$oid":baasClient.authedId()}, "number_status":"unverified"},
              {$set:{
                "phone_number":"+1" + this._number.value,
                "number_status":"pending",
                "verify_code":code}
              }).then(
                () => { this.props.onSubmit() }
              )
          }
        )
      }
    }
  },
  render: function(){
    return (
      <div>
        <div>Enter your phone number. We'll send you a text to confirm.</div>
        <input type="textbox" name="number" ref={(n)=>{this._number=n}} placeholder="number" onKeyDown={this.saveNumber}/>
      </div>
    )
  }
})

var Settings = React.createClass({
  getInitialState: function(){
    return {user:null}
  },
  loadUser: function(){
    users.find({}, null).then((data)=>{
      if(data.result.length>0){
        this.setState({user:data.result[0]})
      }
    })
  },
  componentWillMount: function(){
    initUserInfo(baasClient.authedId())
    this.loadUser()
  },
  render: function(){
    return (
      <div>
        <Link to="/">Lists</Link>
        {
         ((u) => {
              if(u != null){
                if(u.number_status==="pending"){
                  return <AwaitVerifyCode onSubmit={this.loadUser}/>
                }else if(u.number_status==="unverified"){
                  return <NumberConfirm onSubmit={this.loadUser}/>
                } else if(u.number_status==="verified"){
                  return (<div>{`Your number is verified, and it's ${u.phone_number}`}</div>)
                }
              }
            })(this.state.user)
        }
      </div>
    )
  }
})

render((
  <div>
    <Router history={browserHistory}>
      <Route path="/" component={Home}/>
      <Route path="/settings" component={Settings}/>
    </Router>
  </div>
), document.getElementById('app'))
