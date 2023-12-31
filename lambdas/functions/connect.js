const { Connection } = require("../lib/connections");

let connection;
const host = process.env.REDIS_HOST;
const port = process.env.REDIS_PORT;
const password = process.env.REDIS_PASSWORD;

exports.handler = async (event, context, callback) => {
  if (!connection) {
    connection = new Connection({ host, port, password });
    await connection.init(event);
  }

  console.log("CONNECTING TO REDIS CLUSTER!!!");
  const connectionStuff = await connection.addConnection(
    "myRoom",
    event.requestContext.connectionId
  );
  console.log("CONNECTED TO REDIS CLUSTER!!!", connectionStuff);
  await connection.publish(
    "myRoom",
    event,
    `${event.requestContext.connectionId} joined to the room.`
  );

  return { statusCode: 200 };
};
