#!/usr/bin/env bash

posix=$(date +%s%N | cut -b1-13)
events="[{\"timestamp\":$posix,\"message\":\"$1: Example event\"}]"

response=$(aws logs put-log-events --log-group-name prod-logs --log-stream-name trunk --log-events "$events")
