import React from 'react';
import {render, findDOMNode} from 'react-dom';
import {Admin, BaasClient, MongoClient} from 'baas';
import {browserHistory, Router, Route, IndexRoute, Link} from 'react-router'
//import AuthControls from "./auth.js"
//import {Home} from "./home.js"
//import Modal from "react-modal"
//import ObjectID from "bson-objectid";
//import { DragSource, DropTarget } from 'react-dnd';
//import { DragDropContext } from 'react-dnd';
//import HTML5Backend from 'react-dnd-html5-backend';
//import {Converter} from 'showdown';
//import { MentionsInput, Mention } from 'react-mentions'

var FontAwesome = require('react-fontawesome');
require("../static/admin.scss")


let admin = new Admin("http://localhost:8080")
window.admin = admin
//a.auth("unique_user@domain.com", "password").then(function(x){
  /*a.listApps().then((y)=>{
    return a.listVars(y[0].name)
  }).then((y)=>{
    console.log(y)
  })*/
//});
//
//

let AppListItem = React.createClass({
  remove(){
    if(confirm("sure you want to delete " + this.props.app.name + "?")) {
      admin.apps().app(this.props.app.name).remove().then(
        ()=>{
          console.log(this.props, this.props.onChange)
          this.props.onChange()
        }
      )
    }
  },
  render(){
    let app = this.props.app
    return (
      <li key={app.name}>
        <span>{app.name}</span>
        <Link to={"/apps/" + app.name}>edit</Link>
        <span onClick={this.remove}>&times;</span>
      </li>
    )
  }
})

let ServiceListItem = React.createClass({
  remove(){
    admin.apps().app(this.props.app.name).services().service(this.props.serviceName).remove().then(
      ()=>{
        this.props.onChange()
      }
    ).catch(console.log)
  },
  render(){
    return (
      <li>
        <span>{this.props.serviceName} ({this.props.service.type})</span>
        <span onClick={this.remove}>&times;</span>
      </li>
    )
  }
})                 

let Home = React.createClass({
  getInitialState(){
    return {apps:[]}
  },
  componentWillMount(){
    this.load()
  },
  load(){
    admin.apps().list().then((apps)=>{this.setState({apps:apps})})
  },
  render(){
    return (
      <div>
        <ul>
        { 
          this.state.apps.map(
            (app)=> (<AppListItem key={app.name} app={app} onChange={this.load}/>)
          )
        }
        </ul>
      </div>
    )
  }
})

let App = React.createClass({
  getInitialState(){
    return {app:{}, services:[]}
  },
  componentWillMount(){
    this.load()
  },
  load(){
    admin.apps().app(this.props.params.name).get().then((app)=>{
      this.setState({app:app})
      return admin.apps().app(this.props.params.name).services().list()
    }).then((svcs) => {
      this.setState({services:svcs})
    })
  },
  render(){
    let svcKeys = Object.keys(this.state.services)
    return (
      <div>
        <div>{this.state.app ? this.state.app.name : null}</div>
        {svcKeys == 0 ? null :
          (<ul>
            {svcKeys.map((svc)=>{
              let svcObj = this.state.services[svc]
              return (
                <ServiceListItem 
                  onChange={this.load} 
                  app={this.state.app} 
                  service={svcObj} 
                  key={svc} 
                  serviceName={svc}/>
              )
            })}
          </ul>)
        }
      </div>
    )
  }
})

render((
  <div>
    <Router history={browserHistory}>
      <Route path="/" client={admin}>
        <IndexRoute component={Home} />
        <Route path="/apps/:name" component={App}/>
      </Route>
    </Router>
  </div>
), document.getElementById('app'))

