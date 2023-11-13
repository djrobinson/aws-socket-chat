module.exports.handler = async (event) => {
  console.log('WE ARE IN AUCTION LAMBDAS!!! ')
  console.log('VAR FROM TERRAFORM: ', process.env.DATABASE_ENDPOINT)
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
