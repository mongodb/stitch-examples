// Get references to page elements
const statusMessage = document.getElementById("auth-type-identifier");
const loginForm = document.getElementById("login-form");
const logoutButton = document.getElementById("logout-button");

// Setup MongoDB Stitch
const APP_ID = "<YOUR APP ID>";
const {
  Stitch,
  UserPasswordCredential,
} = stitch;
const stitchClient = Stitch.initializeDefaultAppClient(APP_ID);

if (stitchClient.auth.isLoggedIn) {
  hideLoginForm();
  revealDashboardContainer();
  build(Date.now());
}

async function handleLogin() {
  const { email, password } = getLoginFormInfo();
  await emailPasswordAuth(email, password);
  build(Date.now());
}

// Authenticate with Stitch as an email/password user
async function emailPasswordAuth(email, password) {
  if (!stitchClient.auth.isLoggedIn) {
    // Log the user in
    const credential = new UserPasswordCredential(email, password);
    await stitchClient.auth.loginWithCredential(credential);
  }
  hideLoginForm();
  revealDashboardContainer();
}

function getPopularToppings() {
  return stitchClient.callFunction("getPopularToppings");
}

function getSalesTimeline(start, end) {
  return stitchClient.callFunction("salesTimeline", [start, end]);
}



/* 
  Instantiate and refresh the data in the dashboard
*/
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



/* UI Management Functions */
function getLoginFormInfo() {
  const emailEl = document.getElementById("emailInput");
  const passwordEl = document.getElementById("passwordInput");
  // Parse out input text
  const email = emailEl.value;
  const password = passwordEl.value;
  // Remove text from login boxes
  emailEl.value = "";
  passwordEl.value = "";
  return { email: email, password: password };
}

function hideLoginForm() {
  const user = stitchClient.auth.user;
  loginForm.classList.add("hidden");
  // Set login status message
  statusMessage.innerText = "Logged in as: " + user.profile.data.email;
};

function revealDashboardContainer() {
  const container = document.getElementById("dashboard-container");
  container.classList.remove("hidden");
}
