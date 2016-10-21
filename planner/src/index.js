import React from 'react';
import {render, findDOMNode} from 'react-dom';
import {BaasClient, MongoClient} from 'baas';
import {browserHistory, Router, Route, Link} from 'react-router'
import AuthControls from "./auth.js"
import {Home} from "./home.js"
import Modal from "react-modal"
import ObjectID from "bson-objectid";
import { DragSource, DropTarget } from 'react-dnd';
import { DragDropContext } from 'react-dnd';
import HTML5Backend from 'react-dnd-html5-backend';
import {Converter} from 'showdown';
import { MentionsInput, Mention } from 'react-mentions'

var md5 = require("blueimp-md5");
var FontAwesome = require('react-fontawesome');
var update = require('react-addons-update');
require("../static/planner.scss")

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
    width                      : '600px',
    marginLeft                 : "auto",
    marginRight                : "auto",
    left                       : '40px',
    right                      : '40px',
    bottom                     : 'auto',
    border                     : 'none',
    background                 : '#fff',
    overflow                   : 'auto',
    WebkitOverflowScrolling    : 'touch',
    borderRadius               : '8px',
    outline                    : 'none',
    padding                    : '20px',
    boxShadow                  : '0 10px 30px rgba(0,0,0,0.3)'
  }
}

let baasClient = new BaasClient("http://localhost:8080/v1/app/planner")
let rootDb = new MongoClient(baasClient, "mdb1").getDb("planner")
let db = {
  _client: baasClient,
  users: rootDb.getCollection("users"),
  boards: rootDb.getCollection("boards"),
  cards : rootDb.getCollection("cards"),
  members : rootDb.getCollection("members"),
}

let Boards = React.createClass({
  getInitialState(){
    return {authInfo: this.props.route.db._client.auth(), username:null}
  },
  componentWillMount(){
    if(!this.state.authInfo){
      browserHistory.push('/')
      return
    }
    this.props.route.db.users.find({authId:{$oid:this.state.authInfo.user._id}}, null)
    .then(
      (data)=>{
        if(data.result.length == 0){
          return;
        }
        this.setState({username:data.result[0]._id})
      }
    )
  },
  render(){
    return (
      <div>
        <div>
          {
            (this.state.authInfo!=null) ?
              React.Children.map(this.props.children,
               (child) => React.cloneElement(child, {
                  username: this.state.username
                })
              )
              : null
          }
        </div>
      </div>
    )
  }
})

let Board = React.createClass({
  getInitialState:function(){
    return {board:{name:"", lists:{}}}
  },
  load: function(){
    this.props.route.db.boards.find(
      {_id:{$oid:this.props.routeParams.id}}, null).then(
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
        let oid = ObjectID().toHexString()
        setObj["lists." + oid] =  {_id: {$oid:oid}, "name":name, "cards":{}}
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
      <div className="container">
        <nav className="navbar">
          <Link className="navbar-brand-link" to="/">BaaS Board</Link>
        </nav>
        <div className="board">
          <h3 className="board-header">{this.state.board.name}</h3>
          <div className="lists">
            { listKeys.map((x)=> {
                let v = this.state.board.lists[x];
                return <List onUpdate={this.load} boardId={this.props.routeParams.id} db={this.props.route.db} key={x} data={v}/>
               })
            }
            { this.state.newList ?
              <div className="task-list">
                <input type="textbox" ref={(n)=>{this._newlistname=n}} onKeyDown={this.newListKeyDown}></input>
              </div>
              :
              <div>
                <button className="create-new-list" onClick={this.newList}>Add a list&hellip;</button>
              </div>
            }
          </div>
        </div>
      </div>
    )
  }
})

const ItemTypes = { CARD: "card", }

const cardSource = {
  beginDrag(props, monitor, component) {
    return {
      serverIndex: props.data.idx,
      summary:props.data.summary,
      index: props.index
    };
  }
}

const cardTarget = {
  drop(props, monitor, component){
    const dragIndex = monitor.getItem().index;
    const hoverIndex = props.index;
    props.moveCardSave(dragIndex, hoverIndex);
  },
  hover(props, monitor, component) {
    const dragIndex = monitor.getItem().index;
    const hoverIndex = props.index;

    // Don't replace items with themselves
    if (dragIndex === hoverIndex) {
      return;
    }

    // Determine rectangle on screen
    const hoverBoundingRect = findDOMNode(component).getBoundingClientRect();

    // Get vertical middle
    const hoverMiddleY = (hoverBoundingRect.bottom - hoverBoundingRect.top) / 2;

    // Determine mouse position
    const clientOffset = monitor.getClientOffset();

    // Get pixels to the top
    const hoverClientY = clientOffset.y - hoverBoundingRect.top;

    // Only perform the move when the mouse has crossed half of the items height
    // When dragging downwards, only move when the cursor is below 50%
    // When dragging upwards, only move when the cursor is above 50%

    // Dragging downwards
    if (dragIndex < hoverIndex && hoverClientY < hoverMiddleY) {
      return;
    }

    // Dragging upwards
    if (dragIndex > hoverIndex && hoverClientY > hoverMiddleY) {
      return;
    }

    // Time to actually perform the action
    props.moveCard(dragIndex, hoverIndex);

    // Note: we're mutating the monitor item here!
    // Generally it's better to avoid mutations,
    // but it's good here for the sake of performance
    // to avoid expensive index searches.
    monitor.getItem().index = hoverIndex;
  },
};


function collect(connect, monitor) {
  return {
    connectDragSource: connect.dragSource(),
    isDragging: monitor.isDragging()
  };
}


function collect2(connect, monitor) {
  return {
  	connectDropTarget: connect.dropTarget(),
  };
}

let Card = DragSource(ItemTypes.CARD, cardSource, collect)(DropTarget(ItemTypes.CARD,  cardTarget, collect2)(
	React.createClass({
		getInitialState: function(){
			return {hovered:false}
		},
		openEdit:function(){
			this.props.openEdit(this.props.data._id)
		},
		render:function(){
			const { text, isDragging, connectDragSource, connectDropTarget} = this.props;
			return connectDropTarget(connectDragSource(
				<div
          style={ {"opacity": (isDragging ? 0 : 1 )} }
					className={"task-list-card" + (this.state.hovered ? " hovered" : "")}
					onMouseOver={this.hoverIn} 
					onMouseOut={this.hoverOut}
					onClick={this.openEdit}>
					<span className="summary">{this.props.data.summary}</span>
          <div className="task-list-card-edit-icon"><FontAwesome name='pencil' /></div>
          {(this.props.data.numComments || 0) > 0 ? <div><FontAwesome name="comment-o" size="lg"/>{this.props.data.numComments}</div> : null}
				</div>
			))
		}
	})
)
)

let List = DragDropContext(HTML5Backend)(
  React.createClass({
    getInitialState:function(){
      return {cards:[], showNewCardBox:false}
    },
    componentDidUpdate: function(){
      if(this._newcard){
        this._newcard.focus()
      }
    },

    moveCardSave: function(dragIndex, hoverIndex) {
      let from= this.state.dragFromCard
      let to= this.state.dragToCard
      if(from.idx == to.idx){
        return
      }
      const db = this.props.db
      const boardId = this.props.boardId
      const listOid = this.props.data._id.$oid
      const oid = ObjectID().toHexString()

      const query = {"_id": {$oid: boardId}}
      let modifier = {}
      modifier[`lists.${listOid}.cards.${from._id.$oid}.idx`] = to.idx
      modifier[`lists.${listOid}.cards.${to._id.$oid}.idx`] = from.idx
      db.boards.update(query, {$set:modifier}).then(this.props.onUpdate)
    },
    moveCard: function(dragIndex, hoverIndex) {
      let fromCard = this.state.cards[dragIndex]
      let toCard = this.state.cards[hoverIndex]
      this.setState(update(this.state, {
        dragFromCard:{
          $set:fromCard,
        },
        dragToCard:{
          $set:toCard,
        },
        cards: {
          $splice: [
            [dragIndex, 1],
            [hoverIndex, 0, fromCard]
          ]
        }
      }));
    },
    componentWillMount: function(newprops){
      this.resetCards(this.props.data)
    },
    componentWillReceiveProps: function(newprops){
      this.resetCards(newprops.data)
    },
    resetCards: function(data){
      const cardsList = Object.keys(data.cards)
      .map(
        (k, i)=> {return data.cards[k]}
      )
      .sort((a,b)=>{return a.idx - b.idx})
      this.setState({cards:cardsList})
    },

    createNewCard : function(summary){
      let db = this.props.db
      let boardId = this.props.boardId
      let listOid = this.props.data._id.$oid
      let oid = ObjectID().toHexString()

      return db.cards.insert([{_id:{$oid:oid}, summary:summary, "author": {"$oid": this.props.db._client.authedId()}}]).then(()=>{
        let setObj = {}
        setObj["lists."+listOid+".cards."+oid] = {_id:{$oid:oid}, summary:summary, idx:(this.state.cards||[]).length+1}
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
          this.createNewCard(summary).then(()=>{this.props.onUpdate()})
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
      unsetObj["lists." + this.props.data._id.$oid] = 1;
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

      let cardsListSorted = this.state.cards
      return (
        <div className="task-list">
          <h4 className="task-list-header">{this.props.data.name}<button className="task-list-header-delete-button" onClick={this.delete}>&times;</button></h4>
          <div>
            { 
              cardsListSorted.map((c, i) => {
                let cid = c._id
                return (
                  <Card
                    data={c} 
                    key={c._id.$oid} 
                    index={i} 
                    moveCard={this.moveCard} 
                    moveCardSave={this.moveCardSave}
                    openEdit={()=>{this.openEditor(cid)}}
                  />
                )
              })
            }
            { this.state.showNewCardBox ? 
              <input className="text-input" type="text" placeholder="Summary" ref={(n)=>{this._newcard=n}} onKeyDown={this.newCardKeyDown}/>
             : null}
          </div>
          <Modal style={modalStyle} isOpen={this.state.modalOpen} onRequestClose={this.onCloseReq}>
            <CardEditor db={this.props.db} boardId={this.props.boardId} listId={this.props.data._id} boardId={this.props.boardId} editingId={this.state.editingId} onUpdate={this.props.onUpdate}/>
          </Modal>
          <button className="task-list-add-card" onClick={this.quickAddCard}>Add card&hellip;</button>
        </div>
      )
    }
  })
)

let CardEditor = React.createClass({
  save: function(){
    let newSummary = this._summary.value;
    this.props.db.cards.update({_id:this.props.editingId}, 
      {$set:{summary:newSummary, description:this._desc.value}},
      false, false)
    .then(()=>{
      let setObj = {}
      setObj[`lists.${this.props.listId.$oid}.cards.${this.props.editingId.$oid}.summary`] = newSummary;
      return this.props.db.boards.update({_id:{$oid:this.props.boardId}}, {$set:setObj}, false, false)
    })
    .then(this.props.onUpdate)
  },
  getInitialState:function(){
    return {data:{summary:"", description:""}}
  },
  loadCard: function(){
    return this.props.db.cards.find({_id:this.props.editingId}).then(
      (data)=>{
        this.setState({data:data.result[0]});
        this._summary.value = data.result[0].summary || "";
        this._desc.value = data.result[0].description || "";
      }
    )
    .then(this.props.update)
  },
  componentWillMount:function(){
    this.loadCard();
  },
  componentDidMount:function(){
  },
  render:function(){
    return (
      <div>
        <input className="text-input ReactModal__Content-input" type="text" placeholder="summary" ref={(n)=>{this._summary=n}}/>
        <div>
          <textarea className="text-area ReactModal__Content-input" placeholder="description" ref={(n)=>{this._desc=n}}/>
        </div>
        <button className="button button-is-primary ReactModal__Content-button" onClick={this.save}>Save</button>
        <CardComments db={this.props.db} cardId={this.props.editingId} listId={this.props.listId} boardId={this.props.boardId} comments={this.state.data.comments || []} onUpdate={this.loadCard} boardUpdate={this.props.onUpdate}/>
      </div>
    )
  }
})

let CardComments = React.createClass({
  deleteComment:function(id){

    this.props.db.cards.update(
      {_id:this.props.cardId},
      {$pull:{"comments":{_id:id}}}
    )
    .then( ()=>{
      let newNumComments = this.props.comments.length-1
      let modifier = {}
      modifier[`lists.${this.props.listId.$oid}.cards.${this.props.cardId.$oid}.numComments`] = newNumComments;
      return this.props.db.boards.update(
        {_id:{$oid:this.props.boardId}},
        {$set:modifier},
        false,false)
      })
    .then(this.props.onUpdate)
    .then(this.props.boardUpdate)
  },
  render:function(){
    return (
      <div className="comments ReactModal__Content-comments">
        <h4 className="comments-heading">Comments</h4>
        {
          this.props.comments.map((k, i)=>{
              return <Comment key={i} comment={k} deleteComment={this.deleteComment}/>
          })
        }
        <PostCommentForm db={this.props.db} onUpdate={this.props.onUpdate} listId={this.props.listId} cardId={this.props.cardId} numComments={this.props.comments.length} boardUpdate={this.props.boardUpdate}/>
      </div>
    );
  },
})

let getMentions = function(text){
  const mentionRegex = /@\[(\w+)\]/g
  let match = mentionRegex.exec(text);
  let mentions = new Set()
  while(match != null){
    mentions.add(match[1])
    match = mentionRegex.exec(text);
  }
  return Array.from(mentions)
}

let PostCommentForm = React.createClass({
	getInitialState(){
		return {commentValue:""}
	},
  postComment:function(){
    if(this.state.commentValue.length==0){
      return
    }
    let comment = this.state.commentValue
    let mentioned = getMentions(this.state.commentValue)
    let emailHash = md5(this.props.db._client.auth().user.data.email)
    let name = this.props.db._client.auth().user.data.name;
    let newCommentId = ObjectID().toHexString()
    this.props.db.cards.update(
      {_id:this.props.cardId},
      {$push:
        {"comments":
          {
            _id: {$oid:newCommentId},
            gravatar: emailHash,
            author: name,
            comment: this.state.commentValue
          }
        }
      }
    ).then(()=>{
			this.setState({commentValue:""})
      let newNumComments = this.props.numComments+1
      // TODO this is only a guess at the correct # of comments.
      // Consistency issue if another client adds a comment concurrently.
      let modifier = {}
      modifier[`lists.${this.props.listId.$oid}.cards.${this.props.cardId.$oid}.numComments`] = newNumComments;
      return this.props.db.boards.update(
        {_id:this.props.boardId},
        {$set:modifier},
        false,false)
    })
    .then(this.props.onUpdate)
    .then(this.props.boardUpdate)
    .then(()=>{
      if(mentioned.length == 0) {
        return;
      }
      return this.props.db._client.executePipeline([
        {
          service:"mdb1",
          action:"find",
          args:{
            database:"planner",
            collection:"users",
            query:{_id:{$in:mentioned}},
          }
        },
        {
          service:"ses1",
          action:"send",
          args:{
            fromAddress:"mike@mongodb.com",
            toAddress:"$item.email",
            subject: name + " mentioned you in a comment.",
            body: comment,
          }
        }
      ])
    })
  },
  render:function(){
    let emailHash = md5(this.props.db._client.auth().user.data.email)
    return (
      <div className="add-comment">
        <div className="add-comment-input-row">
          <img className="add-comment-gravatar" src={"https://www.gravatar.com/avatar/" + emailHash}/>
          <MentionsInput className="add-comment-text-area" markup={"@[__id__]"} value={this.state.commentValue} placeholder="Write a comment..." onChange={this.handleChange}>
              <Mention trigger="@" data={this.lookupUser} renderSuggestion={this.renderUserSuggestion}/>
          </MentionsInput>
        </div>
        <button className="button button-is-small add-comment-button" onClick={this.postComment}>Comment</button>
      </div>
    )
  },
	handleChange:function(ev, value){
		this.setState({commentValue:value})
	},
	renderUserSuggestion:function (entry, search, highlightedDisplay, index){
		return (
      <div className="mention-suggestion">{highlightedDisplay}</div>
    )
	},
	lookupUser:function(search, callback){
    if(search.length==0){
      callback([])
      return
    }
    this.props.db.users.find(
      {_id: {"$regex":"^"+search,"$options":""}}
    ).then((data)=>{
      callback(
        data.result.map( (u)=>{return {id:u._id, display:(u.name || u._id)}})
      )
    })
  },
})

let Comment = React.createClass({
  render:function(){
    return (
      <div className="comment ReactModal__Content-comment">
        <button className="comment-delete-button" onClick={()=>{this.props.deleteComment(this.props.comment._id)}}>&times;</button>
        <img className="comment-gravatar" src={"https://www.gravatar.com/avatar/" + this.props.comment.gravatar}/>
        <span className="comment-author">{this.props.comment.author}</span>
        <span className="comment-timestamp-prefix">at</span>
        <span className="comment-timestamp">4:20PM 20 October, 2016</span>
        <div className="comment-text">{this.props.comment.comment}</div>
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
