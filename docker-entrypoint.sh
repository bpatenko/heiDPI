#!/bin/bash

MY_INFO="\
###########################################
###          heidpi nDPId Image      ###
###########################################

Starting services
----------------------------------
"

echo "$MY_INFO"

# exit script if any command fails (non-zero value)
set -e
params_ndpisrvd=()
params_ndpid=()

###########################################
### Create params for nDPIsrvd ###
###########################################

[[ $MAX_BUFFERED_LINES -gt 0 ]] && params_ndpisrvd+=(-C $MAX_BUFFERED_LINES)

###########################################
### Create params for nDPId ###
###########################################

regex='(https?|ftp|file)://[-[:alnum:]\+&@#/%?=~_|!:,.;]*[-[:alnum:]\+&@#/%=~_|]'

if [[ $JA3_URL =~ $regex ]]; then
    curl "$JA3_URL" > /root/ja3_fingerprints.csv
    params_ndpid+=(-J /root/ja3_fingerprints.csv)
fi

if [[ $SSL_SHA1_URL =~ $regex ]]; then
    curl "$SSL_SHA1_URL" > /root/sslblacklist.csv
    params_ndpid+=(-S /root/sslblacklist.csv)
fi

[[ -n $INTERFACE ]] && params_ndpid+=(-i $INTERFACE)

[[ $MAX_THREADS -gt 0 ]] && params_ndpid+=(-C $MAX_THREADS)

[[ $FLOW_ANALYSIS = true ]] && params_ndpid+=(-A)

[[ -n $TUNE_PARAM ]] && params_ndpid+=(-o $TUNE_PARAM)

[[ -n $PCAP_FILTER ]] && params_ndpid+=(-B $PCAP_FILTER)

[[ -n $NDPI_CUSTOM_PROTOCOLS ]] && params_ndpid+=(-P $NDPI_CUSTOM_PROTOCOLS)

[[ -n $NDPI_CUSTOM_CATEGORIES ]] && params_ndpid+=(-C $NDPI_CUSTOM_CATEGORIES)

[[ -n $HOSTNAME ]] && params_ndpid+=(-a $HOSTNAME)

###########################################
### Start nDPIsrvd ###
###########################################

echo "Start nDPIsrvd"

/root/nDPIsrvd -p /tmp/nDPIsrvd-daemon.pid \
            -c /tmp/nDPIsrvd-daemon-collector.sock \
            -s /tmp/nDPIsrvd-daemon-distributor.sock \
            -S 0.0.0.0:$PORT \
            -u root \
            -d \
            -L /tmp/nDPIsrvd.log \
            "${params_ndpisrvd[@]}"

###########################################
### Start nDPId ###
###########################################

echo "Start nDPId"

exec /root/nDPId -p /tmp/nDPId-daemon.pid \
            -c /tmp/nDPIsrvd-daemon-collector.sock \
            -u root \
            -L /tmp/nDPId.log \
            "${params_ndpid[@]}"
