Adding comments to a blog with Stitch
-------------

In this example, we'll start with a very simple blog page and add commenting functionality.

We'll do it all in a single html file just for simplicity.

First, start with this in a file called `blog.html`

```html
<html>
   <head>
   </head>
   <body>
       <h3>This is a great blog post</h3>
       <div id="content">
           I like to write about technology. Because I want to get on the front page of hacker news.
       </div>
   </body>
</html>
```

Next we'll startup a simple python webserver

```bash
python -m SimpleHTTPServer
```

Now browse to [the page](http://localhost:8000/blog.html)

Ok, we have our basic page, time to add comments.

Browse to your stitch application home page, on it you should see a script tag to load the stitch sdk and connect.
Copy the first few lines that should look something like:

```js
<script src="https://s3.amazonaws.com/stitch-sdks/js/library/stable/stitch.min.js"></script>
<script>
   const client = new stitch.StitchClient('mdbw17s1-poiib');
   const db = client.service('mongodb', 'mongodb-atlas').db('blog');
   // ...
</script>
```

For the `db` argument, change the name to `blog` from whatever was there before.

This is the basic setup code.

Next we are going to add an onLoad handler.

Add a function in the script block:

```js
function displayCommentsOnLoad() {
  client.login().then(displayComments)
}
```

And make your body tag look like:

```html
  <body onload="displayCommentsOnLoad()">
```

That function first logs the user into stitch anonymously, and then displays any comments in the database.

Since `dispayComments` doesn't exist, lets add it:

```js
function displayComments() {
   db.collection('comments').find({}).then(docs => {
       var html = docs.map(c => "<div>" + c.comment + "</div>").join("");
       document.getElementById("comments").innerHTML = html;
   });
}
```

Reload the page, and you'll actually get an error!

The namespace `blog.comments` isn't known to stitch so it won't let you query it.
Lets fix that
* Browse to the Stitch admin interface
* Click on your atlas cluster
* Click on the rules tab
* Click "Add Namespace"
* Create it with db: blog collection: comments
* Now on the filtes table remove the filter there using delete since we aren't creating privately owned data.
* Now on the Fields tab, click top level document
* Make the READ rule empty `{}` and leave the write rule as is. This means that anyone can ready anything in the collection, but you can only edit or delete your own comments.

Now lets reload our page again and it should work.
Of course we have no comments, so lets fix that.

At the bottom of the html file, add

```html
  <hr>
  <div id="comments"></div>
  <hr>
  Add a Comment: <input id="new_comment"><button type="submit" onclick="addComment()">
```

This creates a little form to add a comment.
Not lets add the addComment function

```js
  function addComment() {
     var foo = document.getElementById("new_comment");
     db.collection("comments").insert({owner_id : client.authedId(), comment: foo.value}).then(displayComments);
     foo.value = "";
  }
```

Now lets try it out!

Now we're using anonymous login for commenting, but you can connect to Google, Facebook, or any oath provider, very easily as well.
You should now be able to add comments to your blog!

The entire thing looks like:


```html
 <html>
     <head>
         <script src="https://s3.amazonaws.com/stitch-sdks/js/library/stable/stitch.min.js"></script>
         <script>
          const client = new stitch.StitchClient('mdbw17s1-poiib');
          const db = client.service('mongodb', 'mongodb-atlas').db('blog');
 
          function displayCommentsOnLoad() {
              client.login().then(displayComments);
          }
 
          function displayComments() {
              db.collection('comments').find({}).then(docs => {
                  var html = docs.map(c => "<div>" + c.comment + "</div>").join("");
                  document.getElementById("comments").innerHTML = html;
              });
          }
          
          function addComment() {
              var foo = document.getElementById("new_comment");
              db.collection("comments").insert({owner_id : client.authedId(), comment: foo.value}).then(displayComments);
              foo.value = "";
          }
          
         </script>
     </head>
     <body onload="displayCommentsOnLoad()">
         <h3>This is a great blog post</h3>
         <div id="content">
             I like to write about technology. Because I want to get on the front page of hacker news.
         </div>
         <hr>
         <div id="comments"></div>
         <hr>
         Add a Comment: <input id="new_comment"><input type="submit" onclick="addComment()">
             
     </body>
 </html>
```
