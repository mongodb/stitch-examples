document.addEventListener('DOMContentLoaded',() => {
    
    'use strict'
    
    // Replace the STITCH-APP-ID with your Stitch Application ID
    // Replace the MONGODB-SERVICE-NAME with the name of the Stitch MongoDB Service
    const stitchClient = new stitch.StitchClient("rest1-vvoul");
    const mongoClient = stitchClient.service("mongodb", "mongodb1");
    
    const db = mongoClient.db("guidebook");
    const coll = db.collection("restaurants");
    
    const writeButton = document.getElementById('button-write');
    const searchButton = document.getElementById('button-search');
    const refreshButton = document.getElementById('button-refresh');
    
    var restaurantName = ""
    
    function doAnonymousAuth(){
        stitchClient.authManager.anonymousAuth().then( result => {
            console.log("authenticated");
            
        }).catch( err => {
            console.error("Error performing auth",err)
        });
    }
    
    function searchRestaurant(text) {
        clearComments()
        
        coll.find({"name" : text }).then( payload => {
            console.log(payload);
            
            if (payload.length == 0){
                document.getElementById("resultFound").innerHTML = "Result not found";
            } else {
                console.log("result returned");
                document.getElementById("resultFound").innerText = "Found Restaurant";
                document.getElementById("cuisine").innerText = payload[0].cuisine;
                document.getElementById("location").innerText = payload[0].location;
                restaurantName = document.getElementById("restaurantName").value;
                
                const comments = payload[0].comments;
                for (var i = 0; i < comments.length; i++){
                    writeComment(comments[i].comment, comments[i].user_id);
                }
            }
        }).catch ( err => {
            console.error("error in search", err);
        });
    }
    
    function writeComment(comment, user_id) {
        var commentFeed = document.getElementById('commentFeed');
        
        var newDiv = document.createElement('div');
        var userName = document.createElement('p');
        var userComment = document.createElement('p');
        
        if (user_id === null){
            const query = {"name" : restaurantName};
            const update = {
                "$push" : {
                    "comments" : {
                        "comment" : comment, 
                        "user_id" : stitchClient.authedId()
                    }
                }
            }
            
            coll.updateOne(query,update).then( () => {
               refreshComments();
            }).catch( err => {
                console.error("Error while adding comment", err)
            });
        } else {
            userComment.appendChild(document.createTextNode(comment))
            userName.appendChild(document.createTextNode("-" + user_id));
        
            newDiv.appendChild(userComment);
            newDiv.appendChild(userName);
            commentFeed.appendChild(newDiv);
        }
    }
    
    function refreshComments() {
        clearComments()
        
        coll.find({"name" : restaurantName}).then( payload => {
            const comments = payload[0].comments;
            for (var i = 0; i < comments.length; i++){
                writeComment(comments[i].comment, comments[i].user_id);
            }
        }).catch( err => { 
            console.error("error while submitting", err)
        });
    }
    
    function clearComments(){
        document.getElementById('commentFeed').innerText = "";
    }
    
    
    writeButton.onclick = () => {
        if (restaurantName != ""){
            
            var inputVal = prompt("Enter your comment : ", "comment");
            writeComment(inputVal, null);
        } else {
            alert("You must search for a valid restaurant to write a comment.")
        }
    }
    
    searchButton.onclick = () => {
        var text = document.getElementById("restaurantName").value;
        searchRestaurant(text);
    }
    
   refreshButton.onclick = () => {
       refreshComments();
   }
    
    doAnonymousAuth()
    
});