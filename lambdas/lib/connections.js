const {
  ApiGatewayManagementApiClient,
  PostToConnectionCommand,
  GetConnectionCommand,
} = require("@aws-sdk/client-apigatewaymanagementapi");
const redis = require("redis");

class Connection {
  constructor(params = {}) {
    this.host = params.host;
    this.port = parseInt(params.port);
    this.password = params.password;
  }

  async init(event) {
    console.log("ripped the init out for a bit");
    const url =
      "https://" +
      event.requestContext.domainName +
      "/" +
      event.requestContext.stage;
    console.log("What is client url? ", url);
    try {
      this.gateway = new ApiGatewayManagementApiClient({
        apiVersion: "2018-11-29",
        endpoint: url,
      });
      console.log("GATEWAY: ", this.gateway.config);
    } catch (e) {
      console.error("ERROR ON INIT ", e);
    }
    this.client = redis.createClient({
      socket: {
        host: process.env.REDIS_CLUSTER_ENDPOINT,
        port: "6379",
        tls: true,
      },
    });
    this.client.on("error", (err) => console.log("Redis Client Error", err));

    await this.client.connect();
  }

  async addConnection(key, connectionId) {
    try {
      return this.client.sAdd(key, connectionId);
    } catch (e) {
      console.error("ERROR ON ADD CONNECTION ", e);
    }
  }

  async removeConnection(key, connectionId) {
    this.client.sRem(key, connectionId);
  }

  async getConnections(key) {
    const members = this.client.sMembers(key);
    return members;
  }

  async publish(key, event, message = null) {
    if (!message) message = event.body;
    const connections = await this.getConnections(key);

    for (const connectionId of connections) {
      if (event.requestContext.connectionId === connectionId) continue;
      try {
        const input = {
          Data: Buffer.from(message), // required
          ConnectionId: connectionId, // required
        };
        const command = new PostToConnectionCommand(input);
        // LOOKS LIKE ASYNC/AWAIT SYNTAX DOESN'T ACTUALLY WORK HERE
        // NEEDED TO USE .THEN() TO GET IT TO WORK
        const redisRes = await this.gateway
          .send(command)
          .then((data) => {
            // process data.
            console.log("PROCESS DATA ", data);
          })
          .catch((error) => {
            console.log("CAUGHT ERROR: ", error);
            // error handling.
          })
          .finally(() => {
            // finally.
          });
        console.log("REDIS RES ", redisRes);
      } catch (e) {
        console.error("ERROR ON PUBLISH ", e);
        this.removeConnection(connectionId);
      }
    }
  }
}

module.exports = { Connection };
