# aws-cloudwatch-subscriptions


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

Building the logging app:

```
env GOOS=linux GOARCH=amd64 go build -o main.so . 
```
