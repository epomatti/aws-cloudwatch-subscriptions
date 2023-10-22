# AWS CloudWatch Logs Subscriptions

CloudWatch Logs subscription filters with Kinesis and several destinations.

<img src=".assets/cw-kinesis.png" width=800 />

Create the resources:

```sh
terraform -chdir="aws" init
terraform -chdir="aws" apply -auto-approve
```

To complete the OpenSearch Serverless setup, connect and create a public Access Policy via the [Console](https://us-east-2.console.aws.amazon.com/aos/home?region=us-east-2#opensearch/collections/prod-logs). (This seems not available via Terraform as of now)

Send static sample logs to the stream:

```sh
aws logs put-log-events --log-group-name prod-logs --log-stream-name trunk --log-events file://events.json
```

Send dynamic timestamped logs:

```sh
bash putLogEvents.sh INFO
bash putLogEvents.sh ERROR
```

To subscribe only to specific logging patterns, edit the filter pattern:

```terraform
subscription_filter_pattern = ""
```

💡 Additional Firehose configurations that are available:

- Data transformation (via Lambda)
- Record format conversion (Parquet, ORC)
- Bucket error prefix
- Dynamic partitioning
- Backup
- Server-side encryption (SSE)
- Destination error logs (CloudWatch)

## Logging from EC2

The `amazon-cloudwatch-agent` package will be installed via user data.

Log into the EC2 instance and configure the CloudWatch agent with the wizard:

```sh
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-config-wizard
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json
```

```sh
systemctl status amazon-cloudwatch-agent
```

Config:

```
https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/create-cloudwatch-agent-configuration-file-wizard.html
https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/install-CloudWatch-Agent-on-EC2-Instance-fleet.html#start-CloudWatch-Agent-EC2-fleet
```


Download the Go app binary:

```sh
curl -L https://github.com/epomatti/aws-cloudwatch-subscriptions/releases/download/v0.0.1/main.so -o main.so
```

Start the app and call the `/info` and `/err` endpoints fro simulating log sync to CloudWatch.

## Local code

From the logging app root:

```sh
go get
go run .
```

Testing the outputs:

```sh
curl localhost:8080/info
curl localhost:8080/err
```

From the logging app root, build it: `./build.sh`
