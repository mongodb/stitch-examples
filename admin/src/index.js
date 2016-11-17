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
      <div key={app.name} className="apps-home-applistitem">
        <span className="applistitem-name">{app.name}</span>
        <div className="applistitem-links">
          <Link className="applistitem-edit" to={"/apps/" + app.name}>edit</Link>
          <span className="applistitem-remove" onClick={this.remove}>&times;</span>
        </div>
      </div>
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
      <div className="svc-list-item">
        <div className="svc-list-item-name">
          <Link 
            className="svc-list-item-editlink"
            to={"/apps/" + this.props.app.name + "/services/" + this.props.serviceName}>
          {this.props.serviceName} ({this.props.service.type})
          </Link>
        </div>
        <div className="svc-list-item-links">
          <div className="svc-list-item-remove" onClick={this.remove}>&times;</div>
        </div>
        <div className="clearfix"/>
      </div>
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
      <div className="apps-home">
        <div className="apps-home-applist">
        { 
          this.state.apps.map(
            (app)=> (<AppListItem key={app.name} app={app} onChange={this.load}/>)
          )
        }
        </div>
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
    return (
      <div className="apphome">
        <div className="title">{this.state.app ? this.state.app.name : null}</div>
        <div className="apptabs">
          <span className="tab apptabs-services">Services</span>
          <span className="tab apptabs-auth">Authentication</span>
        </div>
        {this.props.children ? React.cloneElement(this.props.children, { app: this.state.app }) : null}
      </div>
    )
  }
})

let AddServiceForm = React.createClass({
  save(){
    admin.apps().app(this.props.app.name).services().create(
      {name:this._name.value, type:this._type.value}).then(this.props.onUpdate)
  },
  render(){
    //  TODO: fetch list of available service types from API.
    let serviceTypes = ["mongodb", "twilio", "http", "aws-ses", "aws-sqs", "github"]
    return (
      <div>
        <label>Service Name<input ref={(n)=>{this._name=n}} type="text"/></label>
        <label>Service Type
          <select ref={(n)=>{this._type=n}}>
            {serviceTypes.map((i)=>
              (<option key={i} value={i}>{i}</option>)
            )}
          </select>
          </label>
          <button onClick={this.save}>Save</button>
      </div>
    )
  }
})

let Services = React.createClass({
  getInitialState(){
    return {services:[], showNewForm:false}
  },
  componentWillMount(){
    this.load()
  },
  load(){
    admin.apps().app(this.props.params.name).services().list().then((svcs) => {
      this.setState({services:svcs})
    })
  },
  render(){
    console.log("state", this.state)
    let svcKeys = Object.keys(this.state.services)
    return (
      <div className="svcs-tab">
        {
          !this.state.showNewForm ?
            <button 
            className="svc-add-button"
            onClick={()=>{this.setState({showNewForm:!this.state.showNewForm})}}>
            Add New&hellip;</button>
            : (<AddServiceForm app={this.props.app} onUpdate={this.load}/>)
        }
        {svcKeys.length == 0 ? null :
          (<div className="svcs-list">
            {
              svcKeys.map((svc)=>{
                let svcObj = this.state.services[svc]
                return (
                  <ServiceListItem 
                    onChange={this.load} 
                    app={this.props.app} 
                    service={svcObj} 
                    key={svc} 
                    serviceName={svc}/>
                )
              })
            }
          </div>)
        }
      </div>
    )
  }
})

let EditService = function(){
  return 
}

render((
  <div>
    <Router history={browserHistory}>
      <Route path="/" client={admin}>
        <IndexRoute component={Home} />
        <Route path="/apps">
          <Route path=":name" component={App}>
            <IndexRoute component={Services}/>
            <Route path="services" component={Services}>
              <Route path=":svcname" component={EditService}/>
            </Route>
          </Route>
        </Route>
      </Route>
    </Router>
  </div>
), document.getElementById('app'))

