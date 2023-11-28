# AWS Socket Chat

### Provision AWS Resources

```
cd terraform
terraform init
terraform apply
```

### Deploy lambdas

```
cd lambdas
npm i
serverless deploy
```

### Start UI

```
cd ui
npm i
npm run dev
```

## TODO:

- [x] Elasticache terraform configuration
- [x] Lambda/VPC terraform configuration
- [x] Bootstrap lambdas with servless
- [x] Share terraform outputs with serverless via ssm
- [x] Verify lambda connection to elasticache
- [x] Code lambda websocket configs
- [x] Connect UI to websocket
- [ ] Configure Cognito terraform
- [ ] Authenticate websocket lambdas
- [ ] Add auth to UI
- [ ] Enable login in UI
