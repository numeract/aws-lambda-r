# aws-lambda-r - Configure AWS for production deployment

## TERMINATE UNUSED INSTANCES

In certain cases, you might want to ensure that EC2 instances are not left running.

1. Go to AWS web console and select a region, e.g., Frankfurt / eu-central-1 region
2. To to EC2 > Instances
3. Manually select running instance created for this activity > Actions button > Instance State > Terminate
