const APP_ID = 'osschat-hvyky'
export default class BaaSService {
  static async create({ BaasClient }) {
    const baasClient = new BaasClient(APP_ID);
    const mongoClient = baasClient.service('mongodb', 'mdb1');

    const instance = new BaaSService();
    instance.baasClient = baasClient;
    instance.mongoClient = mongoClient;

    await instance.createViewer();

    return instance;
  }

  createViewer() {
    this.viewer = this.baasClient.auth();
    if (!this.viewer) {
      return this.baasClient.authManager.anonymousAuth().then(
        ()=> {
          console.log("got auth", this.baasClient.auth())
          this.viewer = this.baasClient.auth();
        }
      );
    }
  }

  getDb() {
    return this.mongoClient.getDb('osschat');
  }
}
