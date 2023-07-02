# aws-cloudwatch-subscriptions

From the Terraform module root do `init` and `apply`.

From the logging app root, build it: `./build.sh`


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
