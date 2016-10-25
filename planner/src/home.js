import React from 'react';
import {Link} from 'react-router'
import AuthControls from './auth.js'

var Home = React.createClass({
  getInitialState: function(){
    return {authed:this.props.route.client.auth() != null, username:null}
  },
  load:function(){
    let authInfo = this.props.route.client.auth()
    if(authInfo==null){
      return
    }
    this.props.route.db.users.find({authId:{$oid:authInfo.user._id}}, null)
    .then(
      (data)=>{
        if(data.result.length == 0){
          return;
        }
        this.setState({username:data.result[0]._id})
      }
    )
  },
  componentWillMount: function() {
    this.load()
  },
  render:function(){
    if(!this.state.authed){
      return (<AuthControls client={this.props.route.client}/>)
    }
    if(!this.state.username){
      return (
        <UsernameSetupForm
          auth={this.props.route.client.auth()} 
          db={this.props.route.db}
          onUpdate={this.load}
        />
      )
    }
    return (
      <div>
        <div>username: {this.state.username}</div>
        {this.state.authed ? (<BoardListing db={this.props.route.db}/>) : <AuthControls client={this.props.route.client}/> }
      </div>
    )
  }
})

let UsernameSetupForm = React.createClass({
  getInitialState:function(){
    return {usernameTaken:false}
  },
  save:function(){
    this.props.db.users.insert(
      [{_id:this._username.value, authId:{$oid:this.props.auth.user._id}, email:this.props.auth.user.data.email, name:this.props.auth.user.data.name}]
    ).then(this.props.onUpdate)
    .catch(
      ()=>{
        this.setState({usernameTaken:true})
      }
    )
  },
  onKeyDown:function(e){
    this.setState({usernameTaken:false})
    if(e.keyCode == 13 && this._username.value.length>0){
      this.save()
    }
  },
  render(){
    return (
      <div>
        <h5>Welcome, {this.props.auth.user.data.name}! Pick a username to get started</h5>
        <input type="textbox" ref={(n)=>{this._username=n}} onKeyDown={this.onKeyDown}/>
        {
          this.state.usernameTaken ? 
            (<div className="taken-name-error">Username is taken</div>)
            : null
        }
      </div>
    )
  }
})


let BoardAdder = React.createClass({
  getInitialState:function(){
    return {adding:false}
  },
  setup: function(){
    this.setState({adding:true})
  },
  cancel: function(){
    this.setState({adding:false})
  },
  save: function(){
    if(this._name.value.length == 0 ){
      return
    }
    this.props.db.boards.insert([{"name":this._name.value, "owner_id": {"$oid": this.props.db._client.authedId()}, "lcount": 0}]).then(
      ()=>{
        this._name.value = ""
        this.setState({adding:false})
        this.props.onUpdate()
      })
  },
  keydown: function(e){
    if(e.keyCode == 13){
      this.save()
    } else if(e.keyCode == 27){
      this.cancel()
    }
  },
  render:function(){
    if(!this.state.adding){
      return (<button className="new-board-button" onClick={this.setup}>+ New Board</button>)
    }else{
      return (
        <div>
          <input type="text" placeholder="name" ref={(n)=>{this._name=n}} onKeyDown={this.keydown}/>
          <button onClick={this.cancel}>Cancel</button>
          <button onClick={this.save} ref={(n)=>{this._save=n}}>Save</button>
        </div>
      )
    }
  }
})

let BoardListing = React.createClass({
  getInitialState: function(){
    return {boards:[]}
  },
  componentWillMount: function(){
    this.loadBoards()
  },
  loadBoards: function(){
    this.props.db.boards.find({}, null).then((data)=>{this.setState({boards:data.result})})
  },
  render:function(){
    return (
      <div>
        <ul className="boards">
          { 
            this.state.boards.map(
              (x)=>{
                return <BoardItem data={x} key={x._id["$oid"]} onUpdate={this.loadBoards}/>
              }
            )
          }
        </ul>
        <BoardAdder db={this.props.db} onUpdate={this.loadBoards}/>
      </div>
    )
  }
})

let BoardItem = React.createClass({
  remove: function(){
    if(confirm(`ey you sure you wanna delete '${this.props.data.name}'?`)){
      boards.remove({_id:this.props.data._id}).then(this.props.onUpdate)
    }
  },
  render:function(){
    return (
      <div className="board">
        <span className="board-name">
          <Link className="board-name-link" to={"/boards/" + this.props.data._id.$oid}>{this.props.data.name}</Link>
        </span>
        <button className="board-delete-button" onClick={this.remove}>&times;</button>
      </div>
    )
  }
})

export {Home};
