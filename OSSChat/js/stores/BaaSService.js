const APP_ID = 'snapdemo-olnby'
export default class BaaSService {
  static async create({ BaasClient }) {
    const baasClient = new BaasClient(APP_ID);
    const mongoClient = baasClient.service('mongodb', 'mongodb1');

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
          this.viewer = this.baasClient.auth();
        }
      );
    }
  }

  getDb() {
    return this.mongoClient.db('osschat');
  }
}
