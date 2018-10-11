import React from "react";
import { render } from "react-dom";
import { Route } from "react-router";
import { BrowserRouter, Link } from "react-router-dom";
import {
Stitch,
RemoteMongoClient,
GoogleRedirectCredential,
FacebookRedirectCredential
} from "mongodb-stitch-browser-sdk";

require("../static/todo.scss");

let appId = "<your-app-id>";

const client = Stitch.initializeDefaultAppClient(appId);

const db = client.getServiceClient(RemoteMongoClient.factory, 
   "mongodb-atlas").db('todo');

let TodoItem = class extends React.Component {
   clicked() {
      this.props.onStartChange();
      this.props.items
         .updateOne(
         { _id: this.props.item._id },
         { $set: { checked: !this.props.item.checked } }
         )
         .then(() => this.props.onChange());
   }

render() {
   let itemClass = this.props.item.checked ? "done" : "";
   return (
      <div className="todo-item-root">
      <label className="todo-item-container" onClick={() => this.clicked()}>
         {this.props.item.checked
            ? <svg
               xmlns="http://www.w3.org/2000/svg"
               fill="#000000"
               height="24"
               viewBox="0 0 24 24"
               width="24"
            >
               <path d="M0 0h24v24H0z" fill="none" />
               <path d="M19 3H5c-1.11 0-2 .9-2 2v14c0 1.1.89 2 2 2h14c1.11 0 2-.9 2-2V5c0-1.1-.89-2-2-2zm-9 14l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z" />
            </svg>
            : <svg
               fill="#000000"
               height="24"
               viewBox="0 0 24 24"
               width="24"
               xmlns="http://www.w3.org/2000/svg"
            >
               <path d="M19 5v14H5V5h14m0-2H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2z" />
               <path d="M0 0h24v24H0z" fill="none" />
            </svg>}
         <span className={"todo-item-text " + itemClass}>
            {this.props.item.text}
         </span>
      </label>
      </div>
   );
}
};

var AuthControls = class extends React.Component {
   constructor(props){
      super(props)
      this.state = {userData:null}
      this.client = props.client;
   }

render() {

   let authed = this.client.auth.isLoggedIn;

   if(client.auth.hasRedirectResult()){
      client.auth.handleRedirectResult().then(user=>{
         this.setState({userData:user.profile.data})
      });
   }
   let logout = () => this.client.auth.logout().then(() => location.reload());
   return (
      <div>
      {authed
         ? <div className="login-header">
            {this.state.userData && this.state.userData.picture
               ? <img src={this.state.userData.picture} className="profile-pic" />
               : null}
            <span className="login-text">
               <span className="username">
                  {this.state.userData && this.state.userData.name ? this.state.userData.name : "?"}
               </span>
            </span>
            <div>
               <a className="logout" href="#" onClick={() => logout()}>
                  sign out
               </a>
            </div>
            <div>
               <a className="settings" href="/settings">settings</a>
            </div>
            </div>
         : null}
      {!authed
         ? <div className="login-links-panel">
            <h2>TODO</h2>
            <div
               onClick={() => this.client.auth.loginWithRedirect(new GoogleRedirectCredential())}
               className="signin-button"
            >
               <svg
                  version="1.1"
                  xmlns="http://www.w3.org/2000/svg"
                  width="18px"
                  height="18px"
                  viewBox="0 0 48 48"
               >
                  <g>
                  <path
                     fill="#EA4335"
                     d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"
                  />
                  <path
                     fill="#4285F4"
                     d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"
                  />
                  <path
                     fill="#FBBC05"
                     d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"
                  />
                  <path
                     fill="#34A853"
                     d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"
                  />
                  <path fill="none" d="M0 0h48v48H0z" />
                  </g>
               </svg>
               <span className="signin-button-text">Sign in with Google</span>
            </div>
            <div
               onClick={() => this.client.auth.loginWithRedirect(new FacebookRedirectCredential())}
               className="signin-button"
            >
               <div className="facebook-signin-logo" />
               <span className="signin-button-text">
                  Sign in with Facebook
               </span>
            </div>
            </div>
         : null}
      </div>
   );
}
};

var TodoList = class extends React.Component {
   loadList() {
      if (!this.client.auth.isLoggedIn) {
         return;
      }
      let obj = this;
      this.items.find({}, {limit: 1000}).asArray().then(docs => {
         obj.setState({ items: docs, requestPending: false });
      });
   }

constructor(props) {
   super(props);

   this.state = {
      items: []
   };
   this.client = props.client;
   this.items = props.items;
}

componentWillMount() {
   this.loadList();
}

checkHandler(id, status) {
   this.items.updateOne({ _id: id }, { $set: { checked: status } }).then(() => {
      this.loadList();
   }, { rule: "checked" });
}

componentDidMount() {
   this.loadList();
}

addItem(event) {
   if (event.keyCode != 13) {
      return;
   }
   this.setState({ requestPending: true });
   this.items
      .insertOne({ text: event.target.value, owner_id: this.client.auth.user.id })
      .then(() => {
      this._newitem.value = "";
      this.loadList();
      });
}

clear() {
   this.setState({ requestPending: true });
   this.items.deleteMany({ checked: true }).then(() => {
      this.loadList();
   });
}

setPending() {
   this.setState({ requestPending: true });
}

render() {
   let loggedInResult = (
      <div>
      <div className="controls">
         <input
            type="text"
            className="new-item"
            placeholder="add a new item..."
            ref={n => {
            this._newitem = n;
            }}
            onKeyDown={e => this.addItem(e)}
         />
         {this.state.items.filter(x => x.checked).length > 0
            ? <div
               href=""
               className="cleanup-button"
               onClick={() => this.clear()}
            >
               clean up
            </div>
            : null}
      </div>
      <ul className="items-list">
         {this.state.items.length == 0
            ? <div className="list-empty-label">empty list.</div>
            : this.state.items.map(item => {
               return (
                  <TodoItem
                  key={item._id.toString()}
                  item={item}
                  items={this.items}
                  onChange={() => this.loadList()}
                  onStartChange={() => this.setPending()}
                  />
               );
            })}
      </ul>
      </div>
   );
   return this.client.auth.isLoggedIn ? loggedInResult : null;
}
};

var Home = function(props) {
return (
   <div>
      <AuthControls {...props}/>
      <TodoList {...props}/>
   </div>
);
};

var AwaitVerifyCode = class extends React.Component {
checkCode(e) {
   let obj = this;
   if (e.keyCode == 13) {
      this.props.users
      .updateOne(
         { _id: this.props.client.auth.authInfo.userId, verify_code: this._code.value },
         { $set: { number_status: "verified" } }
      )
      .then(data => {
         obj.props.onSubmit();
      });
   }
}

render() {
   return (
      <div>
      <h3>Enter the code that you received via text:</h3>
      <input
         type="textbox"
         name="code"
         ref={n => {
            this._code = n;
         }}
         placeholder="verify code"
         onKeyDown={e => this.checkCode(e)}
      />
      </div>
   );
}
};

let formatPhoneNum = raw => {
let number = raw.replace(/\D/g, "");
let intl = (raw[0] === "+");
return intl ? "+" + number : "+1" + number;
};

let generateCode = len => {
let text = "";
let digits = "0123456789";
for (var i = 0; i < len; i++) {
   text += digits.charAt(Math.floor(Math.random() * digits.length));
}
return text;
};

var NumberConfirm = class extends React.Component {
saveNumber(e) {
   if (e.keyCode == 13) {
      if (formatPhoneNum(this._number.value).length >= 10) {
      let code = generateCode(7);
      console.log(this._number.value, code)
      this.props.client
         .callFunction("sendConfirmation", [this._number.value, code])
         .then(data => {
            this.props.users
            .updateOne(
               { _id: this.props.client.auth.authInfo.userId, number_status: "unverified" },
               {
                  $set: {
                  phone_number: formatPhoneNum(this._number.value),
                  number_status: "pending",
                  verify_code: code
                  }
               }
            )
            .then(() => {
               this.props.onSubmit();
            });
         })
         .catch(e => {
            console.log(e);
         });
      }
   }
}

render() {
   return (
      <div>
      <div>Enter your phone number. We'll send you a text to confirm.</div>
      <input
         type="textbox"
         name="number"
         ref={n => {
            this._number = n;
         }}
         placeholder="number"
         onKeyDown={e => this.saveNumber(e)}
      />
      </div>
   );
}
};
var Settings = class extends React.Component {
constructor(props) {
   super(props);
   this.state = {
      user: null
   };
   this.client = props.client;
   this.users = props.users;
}
initUserInfo() {
   return this.users
      .updateOne(
      { _id: this.client.auth.user.id },
      { $setOnInsert: { phone_number: "", number_status: "unverified" } },
      { upsert: true }
      )
};
loadUser() {
   this.users.find({_id: this.client.auth.user.id}, null).asArray().then(data => {
      if (data.length > 0) {
      this.setState({ user: data[0] });
      }
   });
}
componentWillMount() {
   this.initUserInfo()
   .then (() => this.loadUser())
}
render() {
   return (
      <div>
      <Link to="/">Lists</Link>
      {(u => {
         if (u != null) {
            if (u.number_status === "pending") {
            return <AwaitVerifyCode onSubmit={() => this.loadUser()} client={this.client} users={this.users} />;
            } else if (u.number_status === "unverified") {
            return <NumberConfirm onSubmit={() => this.loadUser()} client={this.client} users={this.users} />;
            } else if (u.number_status === "verified") {
            return (
               <div
               >{`Your number is verified, and it's ${u.phone_number}`}</div>
            );
            }
         }
      })(this.state.user)}
      </div>
   );
}
};

let items = db.collection("items");
let users = db.collection("users");
let props = {client, items, users};

render(
<BrowserRouter>
   <div>
      <Route exact path="/" render={routeProps => <Home {...props} {...routeProps}/>}/>
      <Route path="/settings" render={routeProps => <Settings {...props} {...routeProps}/>}/>
   </div>
</BrowserRouter>,
document.getElementById("app")
);
