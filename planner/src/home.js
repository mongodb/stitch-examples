import React from 'react';
import {Link} from 'react-router'
import AuthControls from './auth.js'

var Home = React.createClass({
  getInitialState: function(){
    return {authed:this.props.route.client.auth() != null}
  },
  render:function(){
    return (
      <div>
        {this.state.authed ? (<BoardListing db={this.props.route.db}/>) : <AuthControls client={this.props.route.client}/> }
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
    this.props.db.boards.insert([{"name":this._name.value}]).then(
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
        <span className="name">
          <Link to={"/boards/" + this.props.data._id.$oid}>{this.props.data.name}</Link>
        </span>
        <button className="delete" onClick={this.remove}>X</button>
      </div>
    )
  }
})

export {Home};
