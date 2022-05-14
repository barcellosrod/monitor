#!/bin/bash

cpu(){
	cpu=$(awk '{u=$2+$4; t=$2+$4+$5; if (NR==1){u1=u; t1=t;} else print int(($2+$4-u1) * 100 / (t-t1)) ""; }' <(grep 'cpu ' /proc/stat) <(sleep 1;grep 'cpu ' /proc/stat))
#	return $cpu
#	cpu=$(ps -A -o pcpu | tail -n+2 | paste -sd+ | bc | awk '{printf("%d\n",$1 + 0.5)}')
	valor_cpu=$cpu
}

mem_used (){
	mem=$(free -m | awk 'NR==2{printf "%.0f ", $3*100/$2 }')
	valor_mem=$mem
}

disk_quota (){
	disk=$(df -h | awk '$NF=="/"{printf "%s", $4}'| cut -d "G" -f1)
	valor_quota=$disk
}

host=$(hostname)
value=$1
if [[ "$value" -eq "" ]];
then
	interval=0.1
else
	interval=$((value-1))
fi

while true;
do
	sleep $interval
	cpu valor_cpu
        mem_used valor_mem
        disk_quota valor_quota
	comando=$(echo -ne "{\"Args\":[\"set\",\"$host\",\"{\\\"CPU\\\":$valor_cpu,\\\"MEM\\\":$valor_mem,\\\"STG\\\":$valor_quota,\\\"DAT\\\":\\\"???\\\"}\"]}")
	peer chaincode invoke -o 192.169.0.9:7050 -C $CHANNEL_NAME -n ${CC_NAME} --peerAddresses peer0.org1.example.com:7051 --peerAddresses peer0.org2.example.com:7051 --peerAddresses peer0.org3.example.com:7051 -c -C channelall -n mycc -c "$comando"
done
