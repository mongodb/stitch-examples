import DB from './db';
import { deprecate } from '../../util';

/**
 * Create a new MongoDBService instance (not meant to be instantiated directly).
 *
 * @class
 * @return {MongoDBService} a MongoDBService instance.
 */
class MongoDBService {
  constructor(baasClient, serviceName) {
    this.baasClient = baasClient;
    this.serviceName = serviceName;
  }

  /**
   * Get a DB instance
   *
   * @method
   * @param {String} databaseName The MongoDB database name
   * @param {Object} [options] Additional options.
   * @return {DB} returns a DB instance representing a MongoDB database.
   */
  db(databaseName, options = {}) {
    return new DB(this.baasClient, this.serviceName, databaseName);
  }
}

// deprecated
MongoDBService.prototype.getDB =
MongoDBService.prototype.getDb =
  deprecate(MongoDBService.prototype.db, 'use `db` instead of `getDB`');


export default MongoDBService;
