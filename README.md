# AWS CloudWatch Logs Subscriptions

Create the resources:

```
terraform init
terraform apply
```

To complete the OpenSearch Serverless setup, connect and create a public Access Policy via the [Console](https://us-east-2.console.aws.amazon.com/aos/home?region=us-east-2#opensearch/collections/prod-logs). (This seems not available via Terraform as of now)

Sent static sample logs to the stream:

```
aws logs put-log-events --log-group-name prod-logs --log-stream-name trunk --log-events file://events.json
```

Send dynamic timestamped logs:

```
bash put-log-events.sh INFO
bash put-log-events.sh ERROR
```

To subscribe only to specific logging patterns, edit the filter pattern:

```terraform
subscription_filter_pattern = ""
```

## Logging from EC2

The `amazon-cloudwatch-agent` package will be installed via user data.

Log into the EC2 instance and configure the CloudWatch agent with the wizard:

```
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-config-wizard
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json
```

Download the Go app binary:

```
curl -L https://github.com/epomatti/aws-cloudwatch-subscriptions/releases/download/v0.0.1/main.so -o main.so
```

Start the app and call the `/info` and `/err` endpoints fro simulating log sync to CloudWatch.

## Local code

From the logging app root:

```
go get
go run .
```

Testing the outputs:

```
curl localhost:8080/info
curl localhost:8080/err
```

From the logging app root, build it: `./build.sh`
