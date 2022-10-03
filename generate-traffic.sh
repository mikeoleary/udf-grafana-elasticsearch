#!/bin/bash

runtime="1 day"
endtime=$(date -ud "$runtime" +%s)

while [[ $(date -u +%s) -le $endtime ]]
do
    RAND1=$(( ( RANDOM % 2 )  + 1 )) #http or https
    if [ $RAND1 -eq 1 ] 
    then export PROTOCOL='http'
    else export PROTOCOL='https'
    fi

    RAND2=$(( ( RANDOM % 60 )  + 1 )) #duration of test in seconds
    RAND3=$(( ( RANDOM % 50 )  + 1 )) #concurrent workers

    RAND4=$(( ( RANDOM % 2 )  + 1 )) #http or https
    if [ $RAND4 -eq 1 ] 
    then export VIP='10.1.10.11'
    else export VIP='10.1.10.12'
    fi
    
    echo "Running a test for $RAND2 seconds with $RAND3 concurrent workers against $PROTOCOL://$VIP"
    hey -z "$RAND2"s -c $RAND3 $PROTOCOL://$VIP #send web requests to HTTP or HTTPS on VIP 1 or 2, for 1-60 seconds, with 1-50 concurrent workers.

done