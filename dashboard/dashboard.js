const appId = "<YOUR APP ID>";
const webhookUrl = "<YOUR WEBHOOK URL>";
const dashboardApiKey = "<YOUR STITCH API KEY>";

var stitchClient, cluster, data;
stitch.StitchClientFactory.create(appId)
  .then(client => {
    stitchClient = client;
    cluster = client.service("mongodb", "mongodb-atlas");
    data = cluster.db("SalesReporting").collection("Receipts");

    return simpleAuth();
    // return apiKeyAuth();
  })
  .then(build)
  .catch(err => console.error(err));

// Log in to Stitch with anonymous authentication
function simpleAuth() {
  return stitchClient.login();
}

// Authenticate with Stitch using an API Key
function apiKeyAuth(client) {
  return client.authenticate("apiKey", dashboardApiKey);
}

function fetchPopularToppings() {
  return fetch(webhookUrl, { method: "POST", mode: "cors" })
    .then(res => res.json())
    .catch(err => console.error(err));
}

function getSalesTimeline(start, end) {
  return stitchClient.executeFunction("salesTimeline", start, end);
}

function build() {
  // buildTable() and buildGraph() come from chart.js
  let now = Date.now();
  let tablePromise = fetchPopularToppings()
    .then(buildTable)
    .catch(err => console.error(err));
  let graphPromise = getSalesTimeline(now - duration, now)
    .then(buildGraph)
    .catch(err => console.error(err));
  Promise.all([tablePromise, graphPromise])
    .then(values => {
      let graphPromiseValue = values[1];
      let salesLine = graphPromiseValue.salesLine;
      let path = graphPromiseValue.path;

      setTimeout(() => refresh(salesLine, path), 1000);
    })
    .catch(err => console.error(err));
}

function refresh(salesLine, path) {
  // refreshTable() and refreshGraph() come from chart.js

  let then = salesLine[salesLine.length - 1].timestamp * 1;
  let now = Date.now();

  let refreshTablePromise = fetchPopularToppings()
    .then(refreshTable)
    .catch(err => console.error(err));
  let refreshGraphPromise = getSalesTimeline(then, now).then(newSalesTimeline =>
    refreshGraph(salesLine, path, newSalesTimeline)
  );
  Promise.all([refreshTablePromise, refreshGraphPromise])
    .then(values => {
      let refreshGraphPromiseValues = values[1];
      let refreshSalesLine = refreshGraphPromiseValues.salesLine;
      let refreshPath = refreshGraphPromiseValues.path;

      setTimeout(() => refresh(refreshSalesLine, refreshPath), 1000);
    })
    .catch(err => console.error(err));
}
