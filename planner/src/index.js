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
import md5 from 'blueimp-md5'
import FontAwesome from 'react-fontawesome'
import {update} from 'react-addons-update'

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

let baasClient = new BaasClient("planner");
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

let boardFromDBObj = function(board){
  const lists = Object.keys(board.lists || {}).map(
    (x, i)=>{
      let list = board.lists[x]
      list.index = i
      let cards = Object.keys(list.cards || {}).map((c)=>{
        return list.cards[c];
      }).sort((a, b)=>{
        return a.idx-b.idx
      })
      list.cards = cards
      return list
    }
  )
  board.lists = lists
  return board
}

function randomFloat(lower,upper){
  return Math.random() * (upper - lower) + lower
}

let Board = React.createClass({
  getInitialState(){
    return {board:{name:"", lists:[]}}
  },
  load(){
    this.props.route.db.boards.find(
      {_id:{$oid:this.props.routeParams.id}}, null).then(
      (data)=>{
        let board = data.result[0];
        this.setState({board:boardFromDBObj(board)})
      })
  },
  componentWillMount(){
    this.load()
  },
  moveCard(from, to){
    let board = this.state.board;
    let fromList = board.lists.find((x)=>(x._id.$oid==from.listId.$oid))
    let fromCard = fromList.cards.find((x)=>(x._id.$oid == from._id.$oid))
    let toList = board.lists.find((x)=>(x._id.$oid==to.listId.$oid))
    if(fromList._id.$oid == toList._id.$oid){
      fromList.cards.splice(from.index, 1)
      fromList.cards.splice(to.index, 0, fromCard)
      board.lists[fromList.index] = fromList
      this.setState({board:board})
    }else{
      let removedCard = fromList.cards.splice(from.index, 1)
      toList.cards.splice(to.index, 0, fromCard)
      board.lists[fromList.index] = fromList
      board.lists[toList.index] = toList
      this.setState({board:board})
    }
  },
  moveCardSave(from, to){
    let board = this.state.board
    let fromList = board.lists.find((x)=>(x._id.$oid==from.originalListId.$oid))
    let toList = board.lists.find((x)=>(x._id.$oid==to.listId.$oid))
    // the data for the "from" card is 
    // actually in the "to" list because it's moved there temporarily,
    // client-side, by the drag/drop UI code.
    let fromCard = toList.cards.find((x)=>(x._id.$oid == from._id.$oid))
    let lowerBound = -1 * Number.MAX_VALUE
    let upperBound = Number.MAX_VALUE

    let prevCard = null
    let nextCard = null
  
    if(to.index > 0){
      lowerBound  = toList.cards[to.index-1].idx
    }
    if(to.index < toList.cards.length-1){
      upperBound = toList.cards[to.index+1].idx
    }
    let newIdx = randomFloat(lowerBound, upperBound)

    let updateSpec = {}
    if(fromList._id.$oid == toList._id.$oid){
      let modifier = {}
      modifier[`lists.${from.listId.$oid}.cards.${from._id.$oid}.idx`] = newIdx
      updateSpec = {"$set":modifier}
    }else{
      // Remove card from the "from" list
      let unsetModifier = {}
      unsetModifier[`lists.${fromList._id.$oid}.cards.${from._id.$oid}`] = 1

      // Insert it in the "to" list
      let setModifier = {}
      fromCard.idx = newIdx
      setModifier[`lists.${toList._id.$oid}.cards.${to.data._id.$oid}`] = fromCard
      updateSpec = {"$set":setModifier, "$unset": unsetModifier}
    }
    this.props.route.db.boards.updateOne({_id:{$oid:this.props.routeParams.id}}, updateSpec).then(this.load) 
  },
  newList(){
    this.setState({newList:true})
  },
  componentDidUpdate(){
    if(this._newlistname){
      this._newlistname.focus()
    }
  },
  newListKeyDown(e){
    if(e.keyCode == 13){
      let name = this._newlistname.value
      if(name.length > 0){
        let setObj = {}
        let oid = ObjectID().toHexString()
        setObj["lists." + oid] =  {_id: {$oid:oid}, "name":name, "cards":{}}
        this.props.route.db.boards.updateOne(
          {_id:{$oid:this.props.routeParams.id}},
          {$set:setObj})
        .then(()=>{
          this._newlistname.value = ""
          this.load()
        })
      }
    } else if(e.keyCode == 27){
      this.setState({newList:false})
    }
  },
  render(){
    //let listKeys = Object.keys(this.state.board.lists || {})
    return (
      <div className="container">
        <nav className="navbar">
          <Link className="navbar-brand-link" to="/">BaaS Board</Link>
        </nav>
        <div className="board-view">
          <h3 className="board-view-header">{this.state.board.name}</h3>
          <div className="lists">
            { this.state.board.lists.map(
              (x)=>
                <List 
                  onUpdate={this.load} 
                  boardId={this.state.board._id.$oid} 
                  moveCard={this.moveCard} 
                  moveCardSave={this.moveCardSave} 
                  db={this.props.route.db} 
                  key={x._id.$oid} 
                  data={x}
                />
              )
            }
            { this.state.newList ?
              <div className="task-list">
                <input type="textbox" ref={ (n)=>{this._newlistname=n} } onKeyDown={this.newListKeyDown}></input>
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
      listId: props.listId,
      serverIndex: props.data.idx,
      originalListId: props.listId,
      summary:props.data.summary,
      _id:props.data._id,
      index: props.index
    };
  }
}

const cardTarget = {
  drop(props, monitor, component){
    const dragIndex = monitor.getItem().index;
    const hoverIndex = props.index;
    let fromListId = monitor.getItem().listId
    let toListId = props.listId
    props.moveCardSave(monitor.getItem(), props)
  },
  hover(props, monitor, component) {
    const dragIndex = monitor.getItem().index;
    const hoverIndex = props.index;

    let sameList = (props.listId.$oid == monitor.getItem().listId.$oid)
    // Don't replace items with themselves
    if (sameList && dragIndex === hoverIndex) {
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
    if(sameList){
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
      props.moveCard(
        {index:dragIndex, listId:monitor.getItem().listId, _id:monitor.getItem()._id},
        {index:hoverIndex, listId:props.listId, _id:props.data._id}
      )
      monitor.getItem().index = hoverIndex;
    }else{
      props.moveCard(
        {index:dragIndex, listId:monitor.getItem().listId, _id:monitor.getItem()._id},
        {index:hoverIndex, listId:props.listId, _id:props.data._id}
      )
      monitor.getItem().index = hoverIndex;
      monitor.getItem().listId = props.listId
    }

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
		getInitialState(){
			return {hovered:false}
		},
		openEdit(){
			this.props.openEdit(this.props.data._id)
		},
		render(){
			const { text, isDragging, connectDragSource, connectDropTarget} = this.props;
			return connectDropTarget(connectDragSource(
				<div
          style={ {"opacity": (isDragging ? 0 : 1 )} }
					className={"task-list-card" + (this.state.hovered ? " hovered" : "")}
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
    getInitialState(){
      return {showNewCardBox:false}
    },
    componentDidUpdate(){
      if(this._newcard){
        this._newcard.focus()
      }
    },
    createNewCard(summary){
      let db = this.props.db
      let boardId = this.props.boardId
      let listOid = this.props.data._id.$oid
      let oid = ObjectID().toHexString()

      return db.cards.insert([{_id:{$oid:oid}, summary:summary, "author": {"$oid": this.props.db._client.authedId()}}]).then(()=>{
        let setObj = {}
        setObj["lists."+listOid+".cards."+oid] = {_id:{$oid:oid}, summary:summary, idx:(this.props.data.cards||[]).length+1}
        return db.boards.updateOne(
          {_id:{$oid:boardId}},
          {$set:setObj})
      }).then(
        this.setState({showNewCardBox:false})
      )
    },
    newCardKeyDown(e){
      if(e.keyCode == 13){
        let summary = this._newcard.value;
        if(summary.length > 0){
          this.createNewCard(summary).then(()=>{this.props.onUpdate()})
        }
      } else if(e.keyCode == 27) {
        this.setState({newList:false})
      }
    },
    quickAddCard(){
      this.setState({showNewCardBox:true})
    },
    delete(){
      let unsetObj = {}
      unsetObj["lists." + this.props.data._id.$oid] = 1;
      this.props.db.boards.updateOne(
        {_id:{$oid:this.props.boardId}},
        {$unset:unsetObj})
      .then(this.props.onUpdate)
    },
    openEditor(cid){
      this.setState({modalOpen:true, editingId: cid})
    },
    onCloseReq(){
      this.setState({modalOpen:false})
    },
    render(){
      let cardsListSorted = this.props.data.cards
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
                    listId={this.props.data._id}
                    originalListId={this.props.data._id}
                    moveCard={this.props.moveCard} 
                    moveCardSave={this.props.moveCardSave}
                    openEdit={()=>{this.openEditor(cid)}}
                  />
                )
              })
            }
            {
              this.state.showNewCardBox ? 
                <input className="text-input" type="text" placeholder="Summary" ref={(n)=>{this._newcard=n}} onKeyDown={this.newCardKeyDown}/>
                : null
            }
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
  save(){
    let newSummary = this._summary.value;
    this.props.db.cards.updateOne({_id:this.props.editingId}, 
      {$set:{summary:newSummary, description:this._desc.value}})
    .then(()=>{
      let setObj = {}
      setObj[`lists.${this.props.listId.$oid}.cards.${this.props.editingId.$oid}.summary`] = newSummary;
      return this.props.db.boards.updateOne({_id:{$oid:this.props.boardId}}, {$set:setObj})
    })
    .then(this.props.onUpdate)
  },
  getInitialState(){
    return {data:{summary:"", description:""}}
  },
  loadCard(){
    return this.props.db.cards.find({_id:this.props.editingId}).then(
      (data)=>{
        this.setState({data:data.result[0]});
        this._summary.value = data.result[0].summary || "";
        this._desc.value = data.result[0].description || "";
      }
    )
    .then(this.props.update)
  },
  componentWillMount(){
    this.loadCard();
  },
  componentDidMount(){ },
  render(){
    return (
      <div>
        <input className="text-input ReactModal__Content-input" type="text" placeholder="summary" ref={(n)=>{this._summary=n}}/>
        <div>
          <textarea className="text-area ReactModal__Content-input" placeholder="description" ref={(n)=>{this._desc=n}}/>
        </div>
        <button className="button button-is-primary ReactModal__Content-button" onClick={this.save}>Save</button>
        <FileAttacher db={this.props.db} cardId={this.props.editingId} listId={this.props.listId} boardId={this.props.boardId} comments={this.state.data.comments || []} onUpdate={this.loadCard} boardUpdate={this.props.onUpdate} files={this.state.data.files || []}>
        </FileAttacher>
        <CardComments db={this.props.db} cardId={this.props.editingId} listId={this.props.listId} boardId={this.props.boardId} comments={this.state.data.comments || []} onUpdate={this.loadCard} boardUpdate={this.props.onUpdate}/>
      </div>
    )
  }
})

let randomString = (n) =>{
  let result = ""
  let chars ='0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'
  for(let i=0;i<n;i++){
    result += chars[Math.floor(Math.random() * chars.length)];
  }
  return result
}

let FileAttacher = React.createClass({
  upload(){
    let key = "planner-files/" + randomString(10)
    let fileObj = this._file.files[0]
    baasClient.executePipeline([
      {
        service:"s31",
        action:"signPolicy",
        args:{
          bucket:"planner-files",
          key: key,
          acl:"public-read",
          contentType:"text/plain",
        }
      }]
    ).then((d)=>{
      let r = d.result[0]
      var data = new FormData();
      data.append("AWSAccessKeyId", r.accessKeyId)
      data.append("key", key)
      data.append("bucket", "planner-files")
      data.append("acl", "public-read")
      data.append("policy", r.policy)
      data.append("signature", r.signature)
      data.append("Content-Type","text/plain")
      data.append("file", fileObj);
      return $.ajax({
        url: 'https://planner-files.s3.amazonaws.com/',
        type: 'POST',
        data: data,
        crossDomain: true,
        cache: false,
        processData: false,
        contentType: false,
       })
    }).then((d)=>{
      return this.props.db.cards.updateOne(
        {_id:this.props.cardId},
        {$push:
          {"files": 
            {
              name: fileObj.name,
              path: "https://planner-files.s3.amazonaws.com/" + key
            }
          }
        }
      )
    })
    .then(this.props.onUpdate)
    .then(this.props.boardUpdate)
    .catch(console.error)
  },
  render(){
    return (
      <div>
        <div>Files</div>
        {this.props.files.length > 0 ?
          (<div>
            {
              this.props.files.map((d) =>{
                return (
                  <div key={d.path}>
                    <a target="_blank" href={d.path}>{d.name}</a>
                  </div>
                )
              })
            }
          </div>) : null }
        <input name="file" type="file" ref={(n)=>{this._file=n}}/> 
        <button onClick={this.upload}>Upload</button>
      </div>
    )
  }
})

let CardComments = React.createClass({
  deleteComment(id){
    this.props.db.cards.updateOne(
      {_id:this.props.cardId},
      {$pull:{"comments":{_id:id}}}
    )
    .then( ()=>{
      let newNumComments = this.props.comments.length-1
      let modifier = {}
      modifier[`lists.${this.props.listId.$oid}.cards.${this.props.cardId.$oid}.numComments`] = newNumComments;
      return this.props.db.boards.updateOne(
        {_id:{$oid:this.props.boardId}},
        {$set:modifier})
      })
    .then(this.props.onUpdate)
    .then(this.props.boardUpdate)
  },
  render(){
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
  postComment(){
    if(this.state.commentValue.length==0){
      return
    }
    let comment = this.state.commentValue
    let mentioned = getMentions(this.state.commentValue)
    let emailHash = md5(this.props.db._client.auth().user.data.email)
    let name = this.props.db._client.auth().user.data.name;
    let newCommentId = ObjectID().toHexString()
    this.props.db.cards.updateOne(
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
      return this.props.db.boards.updateOne(
        {_id:this.props.boardId},
        {$set:modifier})
    })
    .then(this.props.onUpdate)
    .then(this.props.boardUpdate)
    .then(()=>{
      if(mentioned.length == 0) {
        return;
      }
      return this.props.db._client.executePipeline([
        {
          action:"sendEmail",
          args:{
            userIds: mentioned,
            comment: comment
          }
        }
      ])
    }).then(()=>{
      if(mentioned.length == 0) {
        return;
      }
      return this.props.db._client.executePipeline([
        {
          action:"sendNotification",
          args:{
            userIds: mentioned
          }
        }
      ])
    })
  },
  render(){
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
	handleChange(ev, value){
		this.setState({commentValue:value})
	},
	renderUserSuggestion(entry, search, highlightedDisplay, index){
		return (
      <div className="mention-suggestion">{highlightedDisplay}</div>
    )
	},
	lookupUser(search, callback){
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
  render(){
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
      <Route path="/login" component={AuthControls} db={db} client={baasClient}/>
      <Route path="boards" db={db} component={Boards}>
        <Route path=":id" component={Board} db={db}/>
      </Route>
    </Router>
  </div>
), document.getElementById('app'))
