export default class MongoClient {
  constructor(db) {
    this.db = db;
    this.baseUrl = "http://localhost:8080/v1/app/test/mdb1"
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
    $.ajax({
      type: 'POST',
      contentType: "application/json",
      url: this.baseUrl,
      data: JSON.stringify(body),
      dataType: 'json'
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
}


