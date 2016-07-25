import cookie from 'cookie_js'

export default class MongoClient {
  constructor(db) {
    this.db = db;
    this.app = "test"
    this.baseUrl = `http://localhost:8080/v1/app/${this.app}`
    this.mongoSvcUrl = `${this.baseUrl}/svc/mdb1`
    this.authUrl = `${this.baseUrl}/auth`
  }

  getBaseArgs(action, collection){
    return {
      action:action,
      arguments:{
        database:this.db,
        collection:collection
      }
    }
  }
  execute(body, callback){
    if (this._authToken() === null) {
      throw "Must auth before execute"
    }

    $.ajax({
      type: 'POST',
      contentType: "application/json",
      url: this.mongoSvcUrl,
      data: JSON.stringify(body),
      dataType: 'json',
      headers: {
        'Authorization': `Bearer ${this._authToken()}`
      }
    }).done((data) => callback(data))
  }

  //  TODO return promises from each of this.
  find(collection, query, project, callback){
    let body = this.getBaseArgs("find", collection)
    body.arguments["query"] = query
    body.arguments["project"] = project
    this.execute(body, callback)
  }

  // delete is a keyword in js, so this is called "remove" instead.
  remove(collection, query, singleDoc, callback){
    let body = this.getBaseArgs("delete", collection)
    body.arguments["query"] = query;
    if(singleDoc){
      body.arguments["singleDoc"] = true;
    }
    this.execute(body, callback)
  }

  insert(collection, documents, callback){
    let body = this.getBaseArgs("insert", collection);
    body.arguments["documents"] = documents;
    this.execute(body, callback)
  }
  update(collection, query, update, upsert, multi, callback){
    let body = this.getBaseArgs("update", collection);
    body.arguments["query"] = query;
    body.arguments["update"] = update;
    body.arguments["upsert"] = upsert;
    body.arguments["multi"] = multi;
    this.execute(body, callback)
  }

  authWithOAuth(providerName){
    window.location.replace(`${this.authUrl}/oauth2/${providerName}?redirect=${encodeURI(window.location)}`);
  }

  _authToken(){
    return localStorage.getItem("authToken")
  }

  recoverAuth(){

    if (this._authToken() !== null) {
      return this._authToken()
    }

    var query = window.location.search.substring(1);
    var vars = query.split('&');
    var authToken = null
    for (var i = 0; i < vars.length; i++) {
        var pair = vars[i].split('=');
        if (decodeURIComponent(pair[0]) == "auth_token") {
            authToken = decodeURIComponent(pair[1]);
            window.history.replaceState(null, "", window.location.href.split('?')[0])
        }
    }

    if (authToken !== null) {
      localStorage.setItem("authToken", authToken)
    }

    return this._authToken()
  }
}


