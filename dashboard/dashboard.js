const appId = "docsuserdashboard-jwazj";

let stitchClient, cluster, data;

// Define dimensions of graph using window size/time
let margins = [
  0.15 * window.innerHeight,
  0.15 * window.innerHeight,
  0.1 * window.innerWidth,
  0.1 * window.innerWidth
];
let width = 0.85 * window.innerWidth;
let height = 0.4 * window.innerHeight;
var duration = 300000;
var now = Date.now();

// X scale will fit all values within the set time interval to window size
// Y scale will fit values from 0-30 within window size
var xScale = d3
  .scaleTime()
  .domain([now - duration, now])
  .range([0, width]);
var yScale = d3
  .scaleLinear()
  .domain([0, 30])
  .range([height, 0]);

// Create a line function that can convert data into X/Y points
// Assign the X/Y functions to plot our Timestamp/Total
var line = d3
  .line()
  .x(d => xScale(d.timestamp))
  .y(d => yScale(d.total))
  .curve(d3.curveBasis);

// Add an SVG element with the desired dimensions and margin.
var graph = d3
  .select("#graph1")
  .append("svg")
  .attr("width", width + margins[1] + margins[3])
  .attr("height", height + margins[0] + margins[2]);
const g = graph
  .append("g")
  .attr("transform", "translate(" + margins[3] + "," + margins[0] + ")");

// Add the x-axis
var xAxis = g
  .append("g")
  .attr("class", "axis axis-x")
  .attr("transform", "translate(0," + height + ")")
  .call((xScale.axis = d3.axisBottom().scale(xScale)));

// Add the y-axis
var yAxis = g
  .append("g")
  .attr("class", "axis axis-y")
  .attr("transform", "translate(-25,0)")
  .call((yScale.axis = d3.axisLeft().scale(yScale)));

simpleAuth();

// Simple login with anonymous authentication
function simpleAuth() {
  stitch.StitchClientFactory.create(appId).then(client => {
    stitchClient = client;
    cluster = client.service("mongodb", "mongodb-atlas");
    data = cluster.db("SalesReporting").collection("Receipts");

    stitchClient.login().then(buildGraph);
  });
}

// Simple login taking email/password authentication from the UI
function emailAuth() {
  var userid = prompt("Enter your User ID:", "");
  var password = prompt("Enter your Password:", "");

  stitch.StitchClientFactory.create(appId).then(client => {
    stitchClient = client;
    cluster = client.service("mongodb", "mongodb-atlas");
    data = cluster.db("SalesReporting").collection("Receipts");

    stitchClient.login(userid, password).then(buildGraph);
  });
}

function buildGraph() {
  // Use Stitch to pull the latest data and then graph it
  var now = Date.now();
  stitchClient
    .executeFunction("salesTimeline", now - duration, now)
    .then(docs => {
      var SalesLine = docs.map(doc => ({
        timestamp: doc["timestamp"],
        total: doc["total"]
      }));

      // Plot the data and then call the refresh loop
      g.path = g
        .append("path")
        .datum(SalesLine)
        .attr("stroke", "mediumturquoise")
        .attr("d", line);

      // Refresh the graph after 1 second
      setTimeout(() => refreshGraph(SalesLine, g.path), 1000);
    });
}

function refreshGraph(SalesLine, path) {
  // Find the updated time range
  var now = Date.now();
  var then = SalesLine[SalesLine.length - 1].timestamp;

  // Get any new sales data from Stitch
  stitchClient.executeFunction("salesTimeline", then, now)
  .then(docs => {
    var newPts = docs.map(doc => ({
      timestamp: doc.timestamp,
      total: doc.total
    }));

    if (newPts.length > 0) {
      // Add new Sales points and remove old points
      for (var pt in newPts) {
        path.datum().push(newPts[pt]);
        path.attr("d", line);
      }

      // Slide x-axis left
      xScale.domain([now - duration, now]);
      xAxis
        .transition()
        .duration(1000)
        .call(xScale.axis);

      // Slide path
      path
        .transition()
        .duration(1000)
        .attr("d", line);
      while (path.datum()[0].timestamp < now - duration) {
        path.datum().shift();
      }
    }
    setTimeout(() => refreshGraph(SalesLine, g.path), 1000);
  });
}
