const { createClient } = require("redis");

module.exports.handler = async (event) => {
  const client = createClient({
    socket: {
      host: process.env.REDIS_CLUSTER_ENDPOINT,
      port: "6379",
      tls: true,
    },
  });

  client.on("error", (err) => console.log("Redis Client Error", err));

  await client.connect();
  await client.set("key", "ayyyy");
  const value = await client.get("key");
  console.log("REDIS GET SET WORKED INSIDE OF LAMBDA!!! ", value);
  return {
    statusCode: 200,
    body: JSON.stringify(
      {
        message: "Go Serverless v3.0! Your function executed successfully!",
        input: event,
      },
      null,
      2
    ),
  };
};
