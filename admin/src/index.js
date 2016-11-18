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

let AppListItem = React.createClass({
  remove(){
    if(confirm("sure you want to delete " + this.props.app.name + "?")) {
      admin.apps().app(this.props.app.name).remove()
        .then(this.props.onChange)
        .fail((r)=>{this.setState({error:r.responseJSON.error})})
        .catch(console.error)
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
    ).catch(console.error)
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
  componentDidMount(){
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
  componentDidMount(){
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
    if(this.state.app.name){
      return (
        <div className="apphome">
          <div className="title">{this.state.app ? this.state.app.name : null}</div>
          <div className="apptabs">
            <span className="tab apptabs-services">
              <Link to={`/apps/${this.state.app.name}/services`} activeClassName="active">Services</Link>
            </span>
            <span className="tab apptabs-auth">
              <Link to={`/apps/${this.state.app.name}/auth`} activeClassName="active">Authentication</Link>
            </span>
            <span className="tab apptabs-variables">
              <Link to={`/apps/${this.state.app.name}/variables`} activeClassName="active">Variables</Link>
            </span>
          </div>
          {
            React.Children.map(
              this.props.children,
              (c)=>(React.cloneElement(c, { app: this.state.app, onUpdate:this.load }))
            )
          }
        </div>
      )
    }else{
      return null
    }
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
  componentDidMount(){
    this.load()
  },
  load(){
    admin.apps().app(this.props.params.name).services().list().then((svcs) => {
      this.setState({services:svcs})
    })
  },
  render(){
    let svcKeys = Object.keys(this.state.services)
    if(!this.props.params.svcname){
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
    }else{
      let svcObj = this.state.services[this.props.params.svcname]
      return (
        <div className="svcs-tab">
          {React.Children.map(this.props.children, (c)=>{
            return React.cloneElement(c, {svcname:this.props.params.svcname, app:this.props.app, service: svcObj, onUpdate:this.load})
          })}
        </div>
      )
    }
  }
})

let EditService = React.createClass({
  getInitialState(){
    return {service:null}
  },
  componentDidMount(){
    this.load()
  },
  load(){
    admin.apps().app(this.props.params.name)
      .services().service(this.props.params.svcname).get().then(
        (d)=>{
          this.setState({service:d})
        }
      )
  },
  render(){
    let svcname = this.props.params.svcname
    let appName = this.props.params.name
    let app = this.props.app;
    if(this.state.service){
      return (
        <div className="service-edit">
          <div className="service-name">{svcname} ({this.state.service.type})</div>
          <div className="service-edit-menu">
            <div className="service-edit-menu-item">
              <Link to={"/apps/" + appName +"/services/" + svcname+"/config"} activeClassName="active">Config</Link>
            </div>
            <div className="service-edit-menu-item">
              <Link to={"/apps/" + appName +"/services/" + svcname+"/triggers"} activeClassName="active">Triggers</Link>
            </div>
            <div className="service-edit-menu-item">
              <Link to={"/apps/" + appName +"/services/" + svcname+"/rules"} activeClassName="active">Rules</Link>
            </div>
          </div>
          <div className="service-edit-content">
            { 
              React.Children.map(this.props.children, (c)=>{
                return React.cloneElement(c, {svcname:svcname, app:app, service: this.state.service, onUpdate:this.load})
              })
            }
          </div>
        </div>
      )
    }
    return (<div></div>)

  }
})

let EditConfig = React.createClass({
  getInitialState(){
    return {config:""}
  },
  componentDidMount(){
    if(this.props.service){
      this._config.value = JSON.stringify(this.props.service.config, null, 2);
    }
  },
  save(){
    let parsedConfig = {}
    try{
      parsedConfig = JSON.parse(this._config.value)
    }catch(err){
      this.setState({error : "Invalid json"})
      return
    }
    admin.apps().app(this.props.params.name)
      .services().service(this.props.params.svcname).setConfig(parsedConfig).then(()=>{
        this.props.onUpdate()
      }).catch(console.error)
  },
  render(){
    return (
      <div className="edit-config">
        {this.state.error ? <Error error={this.state.error}/> : null}
        <textarea ref={(n)=>{this._config=n}} className="edit-config-text"></textarea>
        <div>
          <button onClick={this.save}>Save</button>
        </div>
      </div>
    )
  }
})

let Error = React.createClass({
  render(){
    return (<div className="error">{this.props.error}</div>)
  }
})

let Rule = React.createClass({
  getInitialState(){
    return {_id:this.props.rule._id}
  },
  resetText(){
    let config = Object.assign({}, this.props.rule)
    delete config._id
    this._config.value = JSON.stringify(config, null, 2)
  },
  componentDidMount(){
    this.resetText()
  },
  remove(){
    admin.apps().app(this.props.app.name)
      .services().service(this.props.svcname)
      .rules().rule(this.state._id)
      .remove()
        .then(this.props.onUpdate)
        .catch(console.error);
  },
  save(){
    let parsedRule = {}
    try{
      parsedRule = JSON.parse(this._config.value)
    }catch(err){
      this.setState({error : "Invalid json"})
      return
    }
    parsedRule._id = this.state._id
    admin.apps().app(this.props.app.name)
      .services().service(this.props.svcname)
      .rules().rule(this.state._id)
      .update(parsedRule)
        .then(()=>{this.props.onUpdate()})
        .catch(console.error);
  },
  render(){
    return (
      <div className="rule-item">
        <textarea ref={(n)=>{this._config=n}} className="rule-item-text">
        </textarea>
        <div className="rule-item-actions">
          <div className="rule-item-delete" onClick={this.remove}>&times;</div>
          <button className="rule-item-save" onClick={this.save}>save</button>
        </div>
        <div className="clearfix"/>
      </div>
    )
  }
})

let EditRules = React.createClass({
  getInitialState(){
    return {showRuleForm:false}
  },
  addRule(){
    admin.apps().app(this.props.app.name)
      .services().service(this.props.svcname)
      .rules().create({})
        .then(this.props.onUpdate)
        .catch(console.error);
  },
  render(){
    return (
      <div className="edit-rules">
        <button className="new-rule" onClick={this.addRule}>Add Rule</button>
        <div className="rules-list">
          {(this.props.service.rules || []).map((x, i)=>{
            return <Rule key={x._id} rule={x} svcname={this.props.svcname} app={this.props.app} onUpdate={this.props.onUpdate}/>
          })}
        </div>
      </div>
    )
  }
})

let EditTriggers =React.createClass({
  render(){
    return (
      <div className="edit-triggers">
        edit triggers
      </div>
    )
  }
})

let Variable = React.createClass({
  getInitialState(){
    return {_id:this.props.variable._id}
  },
  resetText(){
    let config = Object.assign({}, this.props.variable)
    delete config._id
    this._config.value = JSON.stringify(config, null, 2)
  },
  componentDidMount(){
    this.resetText()
  },
  remove(){
    admin.apps().app(this.props.app.name)
      .variables().variable(this.props.variable.name).remove()
      .then(this.props.onUpdate)
      .catch(console.error);
  },
  save(){
    let parsedVar = {}
    try{
      parsedVar = JSON.parse(this._config.value)
    }catch(err){
      this.setState({error : "Invalid json"})
      return
    }
    parsedVar._id = this.state._id
    admin.apps().app(this.props.app.name)
      .variables().variable(this.props.variable.name).update(parsedVar)
        .then(()=>{this.props.onUpdate()})
        .fail((r)=>{this.setState({error:r.responseJSON.error})})
  },
  render(){
    return (
      <div className="variable-item">
        {this.state.error ? <Error error={this.state.error}/> : null}
        <textarea ref={(n)=>{this._config=n}} className="var-item-text">
        </textarea>
        <div className="variable-item-actions">
          <div className="variable-item-delete" onClick={this.remove}>&times;</div>
          <button className="variable-item-save" onClick={this.save}>save</button>
        </div>
        <div className="clearfix"/>
      </div>
    )
  }
})

let Variables = React.createClass({ 
  getInitialState(){
    return {error:null}
  },
  save(){
    let parsedVar = {}
    admin.apps().app(this.props.app.name).variables().create({
      name:this._name.value,
      type:this._type.value,
    }).then(this.props.onUpdate)
      .fail((r)=>{this.setState({error:r.responseJSON.error})})

  },
  render(){
    let varKeys = Object.keys(this.props.app.variables || {})
    return (
      <div className="edit-variables">
        <div className="variable-add">
          {this.state.error ? <Error error={this.state.error}/> : null}
          <div>New Variable</div>
          <input type="text" placeholder="variable name" ref={(n)=>{this._name=n}}></input>
          <select ref={(n)=>{this._type=n}}>
            <option value="pipeline">Pipeline</option>
            <option value="literal">Literal</option>
          </select>
          <button onClick={this.save}>Save</button>
        </div>
        <div className="variables-list">
          {varKeys.map((v)=>{
            let variable = this.props.app.variables[v];
            return <Variable app={this.props.app} key={v} variable={variable} onUpdate={this.props.onUpdate}/>
          })}
        </div>
      </div>
    )
  }
})

let AuthProvider = React.createClass({ 
  getInitialState: () => ({error:null}),
  componentDidMount(){
    if(this.props.provider){
      this._config.value = JSON.stringify(this.props.provider, null, 2);
    }
  },
  render(){
    return (
      <div className="auth-provider-edit-config">
        <div>{this.props.id}</div>
        {this.state.error ? <Error error={this.state.error}/> : null}
        <textarea ref={(n)=>{this._config=n}} className="edit-config-text"></textarea>
        <div>
          <button onClick={this.save}>Save</button>
        </div>
      </div>
    )
  }
})

let Authentication = React.createClass({ 
  getInitialState(){
    return {error:null, providers:{}, editing:{}}
  },
  load(){
    admin.apps().app(this.props.app.name).authProviders().list()
    .then((d)=>{
      this.setState({providers:d})
      if(d["oauth2/facebook"]){
        this._fbId.value = d["oauth2/facebook"].clientId
        this._fbSecret.value = d["oauth2/facebook"].clientSecret
      }
      if(d["oauth2/google"]){
        this._googId.value = d["oauth2/google"].clientId
        this._googSecret.value = d["oauth2/google"].clientSecret
      }
    })
    .catch(console.error)
  },
  editing(pName, val){
    if(val === undefined){
      return this.state.editing[pName]
    }
    let editing = Object.assign({}, this.state.editing)
    editing[pName] = val
    this.setState({editing})
  },
  remove(pName){
    if(pName in this.state.providers){
      // need to delete it
      let pParts = pName.split("/")
      admin.apps().app(this.props.app.name).authProviders().provider(pParts[0], pParts[1])
      .remove()
        .then(this.load)
        .catch(console.error)
    }else{
      // need to unset editing form
      this.editing(pName, false)
    }
  },
  componentDidMount(){
    this.load()
  },
  enable(pName){
    let pParts = pName.split("/")
    let data = {authType : pParts[0], authName: pParts[1]}
    admin.apps().app(this.props.app.name).authProviders().create(data)
      .then(this.load)
      .catch(console.error)
  },
  save(pName, data){
    let pParts = pName.split("/")
    admin.apps().app(this.props.app.name).authProviders().provider(pParts[0], pParts[1])
    .update(data)
      .then(this.load)
      .catch(console.error)
  },
  render(){
    let pKeys = Object.keys(this.state.providers || {})
    return (
      <div className="edit-auth">
        <div className="auth-provider">
          <div className="auth-provider-name">local/userpass</div>
          {"local/userpass" in this.state.providers ?
            <button onClick={()=>{this.remove("local/userpass")}}>Disable</button> :
            <button onClick={()=>{this.enable("local/userpass")}}>Enable</button>
          }
        </div>
        <div className="auth-provider">
          <div className="auth-provider-name">oauth2/facebook</div>
          {"oauth2/facebook" in this.state.providers || this.editing("oauth2/facebook") ?
            <div>
              <div className="auth-provider-input"><label>Client ID<input type="text" ref={(n)=>{this._fbId=n}}/></label></div>
              <div className="auth-provider-input"><label>Client Secret<input type="text" ref={(n)=>{this._fbSecret=n}}/></label></div>
              <div>
                <button onClick={
                    ()=>{
                      this.save("oauth2/facebook",
                        {clientId:this._fbId.value,clientSecret:this._fbSecret.value}
                      )
                }}> Save </button>
                <button onClick={()=>{this.remove("oauth2/facebook")}}>Disable</button>
              </div>
            </div> : <button onClick={()=>{this.enable("oauth2/facebook")}}>Enable</button> 
          }
        </div>
        <div className="auth-provider">
          <div className="auth-provider-name">oauth2/google</div>
          {"oauth2/google" in this.state.providers || this.editing("oauth2/google") ?
            <div>
              <div><label>Client ID<input type="text" ref={(n)=>{this._googId=n}}/></label></div>
              <div><label>Client Secret<input type="text" ref={(n)=>{this._googSecret=n}}/></label></div>
                <button onClick={
                    ()=>{
                      this.save("oauth2/google",
                        {clientId:this._googId.value,clientSecret:this._googSecret.value}
                      )
                }}> Save </button>
              <button onClick={()=>{this.remove("oauth2/google")}}>Disable</button>
            </div> : <button onClick={()=>{this.enable("oauth2/google")}}>Enable</button> 
          }
        </div>
      </div>
    )
  }
})

render((
  <div>
    <Router history={browserHistory}>
      <Route path="/" client={admin}>
        <IndexRoute component={Home} />
        <Route path="/apps">
          <Route path=":name" component={App}>
            <IndexRoute component={Services}/>
            <Route path="auth" component={Authentication}/>
            <Route path="variables" component={Variables}/>
            <Route path="services" component={Services}>
              <Route path=":svcname" component={EditService}>
                <Route path="config" component={EditConfig}/>
                <Route path="rules" component={EditRules}/>
                <Route path="triggers" component={EditTriggers}/>
              </Route>
            </Route>
          </Route>
        </Route>
      </Route>
    </Router>
  </div>
), document.getElementById('app'))

