const appId = "<YOUR APP ID>";

const statusMessage = document.getElementById("auth-type-identifier");
const loginForm = document.getElementById("login-form");
const logoutButton = document.getElementById("logout-button");

var stitchClient;
stitch.StitchClientFactory.create(appId)
  .then(client => {
    stitchClient = client;
    if (stitchClient.authedId()) {
      stitchClient.logout()
    }
  })
  .catch(err => console.error(err));

function handleLogin() {
  getLoginFormInfo()
    .then(user => emailPasswordAuth(user.email, user.password))
    .then(() => build(Date.now()))
    .catch(err => console.error(err));
}

// Authenticate with Stitch as an email/password user
function emailPasswordAuth(email, password) {
  if (stitchClient.authedId()) {
    return hideLoginForm()
  }
  return stitchClient.login(email, password)
           .then(hideLoginForm)
           .catch(err => console.error('e', err))
}

function getPopularToppings() {
  return stitchClient.executeFunction("getPopularToppings");
}

function getSalesTimeline(start, end) {
  return stitchClient.executeFunction("salesTimeline", start, end);
}

function getLoginFormInfo() {
  const emailEl = document.getElementById("emailInput");
  const passwordEl = document.getElementById("passwordInput");
  // Parse out input text
  const email = emailEl.value;
  const password = passwordEl.value;
  // Remove text from login boxes
  emailEl.value = "";
  passwordEl.value = "";
  return new Promise(resolve => resolve({ email: email, password: password }));
}

const hideLoginForm = () => {
  return stitchClient.userProfile().then(user => {
    // Hide login form
    loginForm.classList.add("hidden");
    // Set login status message
    statusMessage.innerText = "Logged in as: " + user.data.email;
  });
};

function build(now) {
  // buildTable() and buildGraph() come from chart.js

  let tablePromise = getPopularToppings()
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

      setTimeout(() => refresh(salesLine, path, Date.now()), 1000);
    })
    .catch(err => console.error(err));
}

function refresh(salesLine, path, now) {
  // refreshTable() and refreshGraph() come from chart.js

  let then = salesLine[salesLine.length - 1].timestamp * 1;

  let refreshTablePromise = getPopularToppings()
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

      setTimeout(() => refresh(refreshSalesLine, refreshPath, Date.now()), 1000);
    })
    .catch(err => console.error(err));
}
