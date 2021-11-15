#!/bin/bash

export COPROC_COUNT=2
export RECORD_SIZE=500
export THROUGHPUT=-1
export PARTITIONS=3
export TIMEOUT=1200000000

export MESSAGES_COUNT=2000 

export BROKERS="44.242.148.141:9092,34.223.48.244:9092,44.234.62.1:9092"
export RPK_PATH="/home/vadim/redpanda/vbuild/go/linux/bin/rpk"
export producer="../../kafka_2.12-3.0.0/bin/kafka-producer-perf-test.sh"
export consumer="../../kafka_2.12-3.0.0/bin/kafka-consumer-perf-test.sh"