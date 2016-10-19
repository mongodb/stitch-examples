import React from 'react';
import {render} from 'react-dom';
import {BaasClient, MongoClient} from 'baas';
import {browserHistory, Router, Route, Link} from 'react-router'
import AuthControls from "./auth.js"
import {Home} from "./home.js"
import Modal from "react-modal"
import ObjectID from "bson-objectid";

require("../static/planner.scss")

import {Converter} from 'showdown';


let modalStyle = {
  overlay : {
    position          : 'fixed',
    top               : 0,
    left              : 0,
    right             : 0,
    bottom            : 0,
    backgroundColor   : 'rgba(0, 0, 0, 0.75)'
  },
  content : {
    position                   : 'absolute',
    top                        : '40px',
    maxWidth                   : '60%',
    marginLeft                 : "auto",
    marginRight                : "auto",
    left                       : '40px',
    right                      : '40px',
    bottom                     : '40px',
    border                     : '1px solid #ccc',
    background                 : '#fff',
    overflow                   : 'auto',
    WebkitOverflowScrolling    : 'touch',
    borderRadius               : '4px',
    outline                    : 'none',
    padding                    : '20px'
  }
}

/*
{
  "_id": ObjectId("58069770ad7dd59e8710d069"),
  "name": "Personal",
  "owner_id": ObjectId("58069770772e2e772a073c99"),
  "lists": {
    "todo": {
      "count": 2,
      "cards": {
        "58069770772e2e8921c99645": {
          "_id": ObjectId("58069770772e2e8921c99645"),
          "idx": 1,
          "text": "hello"
        },
        "58069770772e2e8921c99646": {
          "text": "it's me",
          "_id": ObjectId("58069770772e2e8921c99646"),
          "idx": 0
        }
      }
    }
  }
}
*/

let baasClient = new BaasClient("http://localhost:8080/v1/app/planner")
let rootDb = new MongoClient(baasClient, "mdb1").getDb("planner")
let db = {
  boards: rootDb.getCollection("boards"),
  cards : rootDb.getCollection("cards"),
  members : rootDb.getCollection("members"),
}

let Boards = function(props){
  return (
    <div>
      <div>
        {props.children}
      </div>
    </div>
  )
}

let Board = React.createClass({
  getInitialState:function(){
    return {board:{name:"", lists:{}}}
  },
  load: function(){
    this.props.route.db.boards.find({_id:{$oid:this.props.routeParams.id}}, null).then(
      (data)=>{this.setState({board:data.result[0], newList:false})}
    )
  },
  componentWillMount: function(){
    this.load()
  },
  newList: function(){
    this.setState({newList:true})
  },
  componentDidUpdate: function(){
    if(this._newlistname){
      this._newlistname.focus()
    }
  },
  newListKeyDown: function(e){
    if(e.keyCode == 13){
      let name = this._newlistname.value
      if(name.length > 0){
        let setObj = {}
        setObj["lists." + name] =  {"name":name, "cards":{}}
        this.props.route.db.boards.update(
          {_id:{$oid:this.props.routeParams.id}},
          {$set:setObj}, false, false)
        .then(()=>{
          this._newlistname.value = ""
          this.load()
        })
      }
    } else if(e.keyCode == 27){
      this.setState({newList:false})
    }
  },
  render:function(){
    let listKeys = Object.keys(this.state.board.lists || {})
    return (
      <div className="board">
        <h3>{this.state.board.name}</h3>

        <div className="lists">
          { listKeys.map((x)=> {
              let v = this.state.board.lists[x];
              return <List onUpdate={this.load} boardId={this.props.routeParams.id} db={this.props.route.db} key={x} name={x} data={v}/>
             })
          }
          { this.state.newList ?
            <div className="list">
              <input type="textbox" ref={(n)=>{this._newlistname=n}} onKeyDown={this.newListKeyDown}></input>
            </div>
            :
            <div className="new-list">
              <button onClick={this.newList}>+ New List</button>
            </div>
          }
        </div>
      </div>
    )
  }
})

let Card = React.createClass({
  getInitialState: function(){
    return {hovered:false}
  },
  hoverIn:function(){
    this.setState({hovered:true})
  },
  hoverOut:function(){
    this.setState({hovered:false})
  },
  openEdit:function(){
    this.props.openEdit(this.props.data._id)
  },
  render:function(){
    return (
      <div
        className={"card-in-list" + (this.state.hovered ? " hovered" : "")}
        onMouseOver={this.hoverIn} 
        onMouseOut={this.hoverOut}
        onClick={this.openEdit}>
        <span className="summary">{this.props.data.summary}</span>
        <span className="edit">edit</span>
      </div>
    )
  }
})


let List = React.createClass({
  getInitialState:function(){
    return {showNewCardBox:false}
  },
  componentDidUpdate: function(){
    if(this._newcard){
      this._newcard.focus()
    }
  },
  createNewCard : function(summary){
    let db = this.props.db
    let boardId = this.props.boardId
    let listName = this.props.name
    let oid = ObjectID().toHexString()
    return db.cards.insert([{_id:{$oid:oid}, summary:summary}]).then(()=>{
      let setObj = {}
      setObj["lists."+listName+".cards."+oid] = {_id:{$oid:oid}, summary:summary}
      db.boards.update(
        {_id:{$oid:boardId}},
        {$set:setObj}, false, false)
    }).then(
      this.setState({showNewCardBox:false})
    )
  },
  newCardKeyDown: function(e){
    if(e.keyCode == 13){
      let summary = this._newcard.value;
      if(summary.length > 0){
        this.createNewCard(summary).then(this.props.onUpdate)
      }
    } else if(e.keyCode == 27) {
      this.setState({newList:false})
    }
  },
	quickAddCard: function(){
		this.setState({showNewCardBox:true})
	},
  delete:function(){
    let unsetObj = {}
    unsetObj["lists." + this.props.name] = 1;
    this.props.db.boards.update(
      {_id:{$oid:this.props.boardId}},
      {$unset:unsetObj}, false, false)
    .then(this.props.onUpdate)
  },
  openEditor:function(cid){
    this.setState({modalOpen:true, editingId: cid})
  },
  onCloseReq:function(){
    this.setState({modalOpen:false})
  },
  render:function(){
    return (
      <div className="list">
        <h4>{this.props.name}<button onClick={this.delete}>X</button></h4>
        <div>
          { 
            Object.keys(this.props.data.cards).map((x) => {
              let c = this.props.data.cards[x]
              let cid = c._id
              return <Card data={c} key={c._id.$oid}
                openEdit={()=>{this.openEditor(cid)}}/>
            })
          }
          { this.state.showNewCardBox ? 
            <input type="textbox" placeholder="summary" ref={(n)=>{this._newcard=n}} onKeyDown={this.newCardKeyDown}/>
           : null}
        </div>
        <Modal style={modalStyle} isOpen={this.state.modalOpen} onRequestClose={this.onCloseReq}>
          <CardEditor db={this.props.db} listName={this.props.name} boardId={this.props.boardId} editingId={this.state.editingId} onUpdate={this.props.onUpdate}/>
        </Modal>
        <button onClick={this.quickAddCard}>Add card...</button>
      </div>
    )
  }
})

let CardEditor = React.createClass({
  save: function(){
    let newSummary = this._summary.value;
    this.props.db.cards.update({_id:this.props.editingId}, 
      {$set:{summary:newSummary, description:this._desc.value}},
      false, false)
    .then(()=>{
      let setObj = {}
      setObj[`lists.${this.props.listName}.cards.${this.props.editingId.$oid}.summary`] = newSummary;
      return this.props.db.boards.update({_id:{$oid:this.props.boardId}}, {$set:setObj}, false, false)
    })
    .then(this.props.onUpdate)
  },
  getInitialState:function(){
    return {data:{summary:"", description:""}}
  },
  componentWillMount:function(){
    this.props.db.cards.find({_id:this.props.editingId}).then(
      (data)=>{
        this.setState({data:data.result[0]});
        this._summary.value = data.result[0].summary || "";
        this._desc.value = data.result[0].description || "";
      }
    )
  },
  componentDidMount:function(){
    //if(this.state.data
    //this._summary.value = this.state.data.summary;
    //this._desc.value = this.state.data.description;
  },
  render:function(){
    return (
      <div>
        <input type="textbox" placeholder="summary" ref={(n)=>{this._summary=n}}/>
        <div>
          <textarea placeholder="description" ref={(n)=>{this._desc=n}}/>
        </div>
        <button onClick={this.save}>Save</button>
      </div>
    )
  }
})

render((
  <div>
    <Router history={browserHistory}>
      <Route path="/" component={Home} db={db} client={baasClient}/>
      <Route path="boards" db={db} component={Boards}>
        <Route path=":id" component={Board} db={db}/>
      </Route>
    </Router>
  </div>
), document.getElementById('app'))
