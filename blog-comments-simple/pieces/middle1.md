
Next we'll startup a simple python webserver

     python -m SimpleHTTPServer

Now browse to [the page](http://localhost:8000/blog.html)

Ok, we have our basic page, time to add comments.

Browse to your stitch application home page, on it you should see a script tag to load the stitch sdk and connect.
Copy the first few lines that should look something like:

            <script src="https://s3.amazonaws.com/stitch-sdks/js/library/298a2b586d91d462099e5d9f66fba0a687837abe/stitch.min.js"></script>
            <script>
               const client = new stitch.StitchClient('eliot1-qffsf');
               const db = client.service('mongodb', 'mongodb1').db('blog');

For the `db` argument, change the name to `blog` from whatever was there before.

This is the basic setup code.

Next we are going to add an onLoad handler.

So add a function in the script block:

         function displayCommentsOnLoad() {
             client.anonymousAuth().then(displayComments)
         }

Add make your body tag look like:

    <body onLoad="displayCommentsOnLoad()">

That function firsts logs the user into stitch anonymously, and then dislpays any comments in the database.

Since `dislpayComments` doesn't exist, lets add it:

         function displayComments() {
             db.collection('comments').find({}).then(docs => {
                 var html = docs.map(c => "<div>" + c.comment + "</div>").join("");
                 document.getElementById("comments").innerHTML = html;
             });
         }

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

        <hr>
        <div id="comments"></div>
        <hr>
        Add a Comment: <input id="new_comment"><input type="submit" onClick="addComment()">

This creates a little form to add a comment.
Not lets add the addComment function

         function addComment() {
             var foo = document.getElementById("new_comment");
             db.collection("comments").insert({owner_id : client.authedId(), comment: foo.value}).then(displayComments);
             foo.value = "";
         }

Now lets try it out!

Now we're using anonymous login for commenting, but you can connect to Google, Facebook, or any oath provider, very easily as well.
You should now be able to add comments to your blog!

The entire thing looks like:






