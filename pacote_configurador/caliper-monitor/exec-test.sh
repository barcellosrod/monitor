#!/bin/bash

npm install --only=prod @hyperledger/caliper-cli@0.4.2
npm install colors@1.4.0
npx caliper bind --caliper-bind-sut fabric:2.2

# Set workspace as caliper-benchmarks root
WORKSPACE="/home/ubuntu/caliper/caliper-benchmarks/caliper-monitor"
# Nominate a target network
NETWORK="network.yaml"

cd ${WORKSPACE}
echo "Workspce: " ${WORKSPACE}

# Available benchmarks
BENCHMARK="config.yaml"

echo "Benchmark: " ${BENCHMARK}
echo "Network: " ${NETWORK}

# Execute Phases
runBenchmark () {
    npx caliper launch manager \
    --caliper-workspace ${WORKSPACE} \
    --caliper-benchconfig ${BENCHMARK} \
    --caliper-networkconfig ${NETWORK} \
    --caliper-flow-only-test \
    --caliper-fabric-gateway-enabled \
    sleep 5s
} 

runBenchmark 
