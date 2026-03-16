# AWS Patterns

Use the find-docs skill (`npx ctx7@latest`) to look up current AWS SDK and service documentation.

## Common Architectures

### Serverless API
```
API Gateway → Lambda → DynamoDB
                    → S3 (file storage)
                    → SQS (async processing)
```

### Container-based
```
ALB → ECS Fargate → RDS PostgreSQL
                  → ElastiCache Redis
                  → S3
```

### Full-stack Web App
```
CloudFront → S3 (static frontend)
          → ALB → ECS/EKS (API)
                          → RDS
                          → ElastiCache
```

## CDK Patterns

### Lambda Function
```typescript
const fn = new lambda.Function(this, 'Handler', {
  runtime: lambda.Runtime.NODEJS_20_X,
  handler: 'index.handler',
  code: lambda.Code.fromAsset('lambda'),
  environment: { TABLE_NAME: table.tableName },
});
table.grantReadWriteData(fn);
```

### API Gateway + Lambda
```typescript
const api = new apigateway.RestApi(this, 'Api');
const resource = api.root.addResource('items');
resource.addMethod('GET', new apigateway.LambdaIntegration(fn));
```

### ECS Fargate Service
```typescript
const service = new ecs_patterns.ApplicationLoadBalancedFargateService(this, 'Service', {
  taskImageOptions: {
    image: ecs.ContainerImage.fromAsset('./app'),
    environment: { DB_HOST: db.instanceEndpoint.hostname },
  },
  desiredCount: 2,
});
```

## Security Best Practices

- Use IAM roles, never access keys in code
- Enable CloudTrail for audit logging
- Use Secrets Manager for credentials
- Enable encryption at rest (KMS) for all data stores
- Use VPC for network isolation
- Enable GuardDuty for threat detection
- Use Security Groups as firewalls (least privilege)

## Cost Optimization

- Use Savings Plans or Reserved Instances for predictable workloads
- Spot Instances for fault-tolerant batch processing
- Right-size instances based on CloudWatch metrics
- Use S3 lifecycle policies for infrequently accessed data
- Enable Cost Explorer and set billing alerts
