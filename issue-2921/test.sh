#!/bin/bash

. ../config.sh

GENERATE_DIR_PATH="./test"
SCRIPTS_DIR_PATH="./scripts"

PRODUCER_DIR="./producer_log"
CONSUMER_DIR="./consumer_log"

rm -rf $SCRIPTS_DIR_PATH
mkdir $SCRIPTS_DIR_PATH

rm -rf $GENERATE_DIR_PATH
$RPK_PATH wasm generate $GENERATE_DIR_PATH
cp simple-transform-template.js $GENERATE_DIR_PATH/src/main.js
cd $GENERATE_DIR_PATH
npm install
npm run build
cd ..
cp $GENERATE_DIR_PATH/dist/main.js $SCRIPTS_DIR_PATH/simple_template.js

rm -rf $GENERATE_DIR_PATH
$RPK_PATH wasm generate $GENERATE_DIR_PATH
cp filter-transform-template.js $GENERATE_DIR_PATH/src/main.js
cd $GENERATE_DIR_PATH
npm install
npm run build
cd ..
cp $GENERATE_DIR_PATH/dist/main.js $SCRIPTS_DIR_PATH/filter_template.js

$RPK_PATH topic create one_to_one3 -p ${PARTITIONS} -r 3 --brokers ${BROKERS}

for (( i=0; i < ${COPROC_COUNT}; i++ ))
do
    template=`cat ${SCRIPTS_DIR_PATH}/simple_template.js`
    new_code=${template//_input/one_to_one3}
    new_code=${new_code//output/simple_${i}}
    echo "$new_code" > $SCRIPTS_DIR_PATH/simple_${i}.js
    $RPK_PATH wasm deploy --name "simple_${i}" $SCRIPTS_DIR_PATH/simple_${i}.js --brokers ${BROKERS}

    template=`cat ${SCRIPTS_DIR_PATH}/filter_template.js`
    new_code=${template//_input/one_to_one3}
    new_code=${new_code//output/filter_${i}}
    echo "$new_code" > $SCRIPTS_DIR_PATH/filter_${i}.js
    $RPK_PATH wasm deploy --name "filter_${i}" $SCRIPTS_DIR_PATH/filter_${i}.js --brokers ${BROKERS}
done

rm -rf ${PRODUCER_DIR}
mkdir ${PRODUCER_DIR}

RECORD_SIZE_NEW=$((${RECORD_SIZE} * 2))
for (( i=0; i < 4; i++ ))
do
    $producer --topic "one_to_one3" --record-size ${RECORD_SIZE} --producer-props asks=-1   bootstrap.servers=${BROKERS} --throughput ${THROUGHPUT} --num-records $MESSAGES_COUNT &> ${PRODUCER_DIR}/producer_${i}.txt &
    $producer --topic "one_to_one3" --record-size ${RECORD_SIZE_NEW} --producer-props asks=-1   bootstrap.servers=${BROKERS} --throughput ${THROUGHPUT} --num-records $MESSAGES_COUNT &> ${PRODUCER_DIR}/producer_${i}.txt &
done

rm -rf ${CONSUMER_DIR}
mkdir ${CONSUMER_DIR}
for (( i=0; i < ${COPROC_COUNT}; i++ ))
do
    expected_messages_simple=$((${MESSAGES_COUNT} * 3))
    $consumer --topic "one_to_one3."'_simple_'"${i}"'_' --bootstrap-server ${BROKERS} --messages ${expected_messages_simple} --timeout ${TIMEOUT} &> ${CONSUMER_DIR}/consumer_simple${i}.txt &
    expected_messages_filter=$((${MESSAGES_COUNT}))
    $consumer --topic "one_to_one3."'_filter_'"${i}"'_' --bootstrap-server ${BROKERS} --messages ${expected_messages_filter} --timeout ${TIMEOUT} &> ${CONSUMER_DIR}/consumer_filter${i}.txt &
done