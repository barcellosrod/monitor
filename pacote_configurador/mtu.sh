#!/bin/bash

retpid=$(docker inspect --format '{{.State.Pid}}' cli) 
echo retpid=$retpid
nsenter -t ${retpid} -n ifconfig eth0 mtu 1300