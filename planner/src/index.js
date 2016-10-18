import React from 'react';
import {render} from 'react-dom';
import {BaasClient, MongoClient} from 'baas';
import {browserHistory, Router, Route , Link} from 'react-router'
import AuthControls from "./auth.js"

require("../static/planner.scss")

let baasClient = new BaasClient("http://localhost:8080/v1/app/planner")
let db = new MongoClient(baasClient, "mdb1").getDb("planner")
let boards = db.getCollection("boards")
let lists = db.getCollection("lists")
let cards = db.getCollection("cards")
let members = db.getCollection("members")

var Home = React.createClass({
  getInitialState: function(){
    return {authed:baasClient.auth() != null}
  },
  render:function(){
    return (
      <div>
        {this.state.authed ? (<Boards/>) : <AuthControls client={baasClient}/> }
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
    if(this._name.value.length == 0 )
      return
    boards.insert([{"name":this._name.value}]).then(
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
      return (<button className="newboard" onClick={this.setup}>+ New Board</button>)
    }else{
      return (
        <div>
          <input type="text" placeholder="name" ref={(n)=>{console.log("called!");this._name=n}} onKeyDown={this.keydown}/>
          <button onClick={this.cancel}>Cancel</button>
          <button onClick={this.save} ref={(n)=>{this._save=n}}>Save</button>
        </div>
      )
    }
  }
})

let Boards = React.createClass({
  getInitialState: function(){
    return {boards:[]}
  },
  componentWillMount: function(){
    this.loadBoards()
  },
  loadBoards: function(){
    boards.find({}, null).then((data)=>{this.setState({boards:data.result})})
  },
  render:function(){
    return (
      <div>
        <ul className="boards">
          { 
            this.state.boards.map(
              (x)=>{
                return <Board data={x} key={x._id["$oid"]} onUpdate={this.loadBoards}/>
              })
          }
        </ul>
        <BoardAdder onUpdate={this.loadBoards}/>
      </div>
    )
  }
})

let Board = React.createClass({
  remove: function(){
    if(confirm(`you sure you wanna delete board ${this.props.data.name}?`)){
      boards.remove({_id:this.props.data._id}).then(this.props.onUpdate)
    }
  },
  /*load:function(){
    boards.find({_id:{$oid:this.props.id}}, null).then((data)=>{this.setState({data:data[0]})})
  },
  componentWillMount:function(){
    this.load()
  },
  */
  render:function(){
    console.log(this.props)
    return (
      <div className="board">
        <span className="name">{this.props.data.name}</span>
        <button className="delete" onClick={this.remove}>X</button>
      </div>
    )
  }
})

render((
  <div>
    <Router history={browserHistory}>
      <Route path="/" component={Home}/>
    </Router>
  </div>
), document.getElementById('app'))
