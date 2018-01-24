#!/usr/bin/env bash
set -x -u
if [ "$#" -lt 4 ]; then
    echo "Incorrect parameters, usage:"
    echo "throttled queue_name file_name [num_maintain]"
    echo "queue_name: The name of the queue that will be read from"
    echo "file_name: The name of the file to read the queue messages from"
    echo "num_maintain [optional, default 50]: The number of items to maintain, i.e. top up the queue to"
    exit
fi
QUEUE_NAME=$1
FILE_NAME=$2
QUEUE_URL=$3
EXCHANGE_NAME=$4
QUEUE_MAINTAIN=${5:-50}

if [ ! -f throttled.tmp ]; then
    echo "1" > throttled.tmp
    index=1
else
   index=$(cat throttled.tmp)
fi

#Read number of items in the queue
numItems=$(sudo rabbitmqctl list_queues | grep "$QUEUE_NAME" | awk -F '\t' '{ print $2 }')
diff=$((QUEUE_MAINTAIN - numItems))
[ $diff -lt 1 ] && exit
start=$index
end=$((index+diff))

sed -n $start,$((end-1))p "$FILE_NAME" | while read MESSAGE; do
  echo "$MESSAGE" | amqp-publish \
    -u "$QUEUE_URL" \
    -e "$EXCHANGE_NAME" \
    -r "$QUEUE_NAME"
  done

echo $end > throttled.tmp