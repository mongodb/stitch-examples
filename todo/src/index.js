import React from 'react';
import {render} from 'react-dom';
import {BaasClient, MongoClient} from 'baas';
import {browserHistory, Router, Route , Link} from 'react-router'

require("../static/todo.scss")

let baasClient = new BaasClient(baseUrl, "todo");
let db = new MongoClient(baasClient, "mdb1").getDb("todo")
let items = db.getCollection("items")
let users = db.getCollection("users")
let TodoItem = React.createClass({
	clicked(){
    this.props.onStartChange();
    items.updateOne({"_id":this.props.item._id}, {$set:{"checked":!this.props.item.checked}})
		.then(this.props.onChange)
	},
	render(){
		let itemClass = this.props.item.checked ? "done" : "";
		return (
			<div className="todo-item-root">
				<label className="todo-item-container" onClick={this.clicked}>
          { this.props.item.checked ? 
            (
              <svg xmlns="http://www.w3.org/2000/svg" fill="#000000" height="24" viewBox="0 0 24 24" width="24">
                <path d="M0 0h24v24H0z" fill="none"/>
                <path d="M19 3H5c-1.11 0-2 .9-2 2v14c0 1.1.89 2 2 2h14c1.11 0 2-.9 2-2V5c0-1.1-.89-2-2-2zm-9 14l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/>
              </svg>
            )
            :
            (
              <svg fill="#000000" height="24" viewBox="0 0 24 24" width="24" xmlns="http://www.w3.org/2000/svg">
                <path d="M19 5v14H5V5h14m0-2H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2z"/>
                <path d="M0 0h24v24H0z" fill="none"/>
              </svg>
            )
          }
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
    let logout = () => this.props.client.logout().then(() => location.reload());
    const userData = baasClient.auth().user.data
    return (
      <div>
        { authed ? 
          (
            <div className="login-header">
              {userData && userData.picture ? 
                <img src={userData.picture} className="profile-pic"/>
                : null
              }
              <span className="login-text">
                <span className="username">{userData && userData.name ? userData.name : "?"}</span>
              </span>
              <div>
                <a className="logout" href="#" onClick={() => logout()}>sign out</a>
              </div>
            </div>
          ) : null
        }
				{	!authed ? 
					<div className="login-links-panel">
            <h2>TODO</h2>
						<div onClick={() => this.props.client.authWithOAuth("google")} className="signin-button">
							<svg version="1.1" xmlns="http://www.w3.org/2000/svg" width="18px" height="18px" viewBox="0 0 48 48">
								<g>
									<path fill="#EA4335" d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"></path>
									<path fill="#4285F4" d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"></path>
									<path fill="#FBBC05" d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"></path>
									<path fill="#34A853" d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"></path>
									<path fill="none" d="M0 0h48v48H0z"></path>
								</g>
							</svg>
							<span className="signin-button-text">Sign in with Google</span>
						</div>
						<div onClick={() => this.props.client.authWithOAuth("facebook")} className="signin-button">
              <div className="facebook-signin-logo"></div>
							<span className="signin-button-text">Sign in with Facebook</span>
            </div>
					</div>
					: null
				}
      </div>
    )
		//<button disabled={authed} onClick={() => this.props.client.linkWithOAuth("google")}>Link with Google</button>
		//<button disabled={authed} onClick={() => this.props.client.linkWithOAuth("facebook")}>Link with Facebook</button>
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
      obj.setState({items:data.result, requestPending:false})
    })
  },

  getInitialState: () => {return {items:[]}},
  componentWillMount: function(){this.loadList()},
  checkHandler: function(id, status){
    items.updateOne({"_id":id}, {$set:{"checked":status}}).then(() => {
      this.loadList();
    }, {"rule": "checked"})
  },
  timerFunc(){
    if(this.state.requestPending){
      console.log("not fetching, request in progress")
      return
    }
    this.loadList()
  },
  componentDidMount(){
    let intervalId = setInterval(this.timerFunc, 1000) 
    this.setState({intervalId: intervalId})
  },
  componentWillUnmount(){
    clearInterval(this.state.intervalId)
  },
  addItem: function(event){
    if(event.keyCode != 13 ){
      return
    }
    this.setState({requestPending:true})
    items.insert([{text:event.target.value, "user": {"$oid": baasClient.authedId()}}]).then(
      () => {
        this._newitem.value = ""
        this.loadList();
      }
    )
  },

  clear: function(){
    this.setState({requestPending:true})
    items.deleteMany({checked:true}).then(() => {
      this.loadList();
    })
  },
  setPending(){
    this.setState({requestPending:true})
  },
  render: function(){
    let loggedInResult = 
      (<div>
				<div className="controls">
        	<input type="text" className="new-item" placeholder="add a new item..." ref={ (n)=>{this._newitem=n} } onKeyDown={this.addItem}/>
					{this.state.items.filter((x)=>x.checked).length > 0 ? 
						<div  href="" className="cleanup-button" onClick={this.clear}>clean up</div>
						: null 
					}
				</div>
        <ul className="items-list">
        { 
          this.state.items.length == 0
          ?  <div className="list-empty-label">empty list.</div>
           : this.state.items.map((item) => {
            return <TodoItem key={item._id.$oid} item={item} onChange={this.loadList} onStartChange={this.setPending}/>;
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
      <AuthControls client={baasClient}/>
      <TodoList/>
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
