#!/bin/bash

# gmx account

# server 1 details
export server1_dns="fmorath@storeoipsjti6wookcsshpublicip6.westeurope.cloudapp.azure.com"
export server1_ip="10.0.0.7"
export server1_port=11211

# server 2 details
export server2_dns="fmorath@storeoipsjti6wookcsshpublicip7.westeurope.cloudapp.azure.com"
export server2_ip="10.0.0.10"
export server2_port=11211

# server 3 details
export server3_dns="fmorath@storeoipsjti6wookcsshpublicip8.westeurope.cloudapp.azure.com"
export server3_ip="10.0.0.6"
export server3_port=11211

# client 1 details
export client1_dns="fmorath@storeoipsjti6wookcsshpublicip1.westeurope.cloudapp.azure.com"
export client1_ip="10.0.0.11"

# client 2 details
export client2_dns="fmorath@storeoipsjti6wookcsshpublicip2.westeurope.cloudapp.azure.com"
export client2_ip="10.0.0.8"

# client 3 details
export client3_dns="fmorath@storeoipsjti6wookcsshpublicip3.westeurope.cloudapp.azure.com"
export client3_ip="10.0.0.5"

# mw 1 details
export mw1_dns="fmorath@storeoipsjti6wookcsshpublicip4.westeurope.cloudapp.azure.com"
export mw1_ip="10.0.0.9"
export mw1_port=16379

# mw 2 details
export mw2_dns="fmorath@storeoipsjti6wookcsshpublicip5.westeurope.cloudapp.azure.com"
export mw2_ip="10.0.0.4"
export mw2_port=16379



function ping {
    echo "start pinging ..."

    ssh $mw1_dns "ping -i 0.2 -c 100 $client1_ip &> mw1_client1_ping.log &" & 
    ssh $mw1_dns "ping -i 0.2 -c 100 $client2_ip &> mw1_client2_ping.log &" & 
    ssh $mw1_dns "ping -i 0.2 -c 100 $client3_ip &> mw1_client3_ping.log &" &
    ssh $mw1_dns "ping -i 0.2 -c 100 $server1_ip &> mw1_server1_ping.log &" &
    ssh $mw1_dns "ping -i 0.2 -c 100 $server2_ip &> mw1_server2_ping.log &" &
    ssh $mw1_dns "ping -i 0.2 -c 100 $server3_ip &> mw1_server3_ping.log &" &

    ssh $mw2_dns "ping -i 0.2 -c 100 $client1_ip &> mw2_client1_ping.log &" & 
    ssh $mw2_dns "ping -i 0.2 -c 100 $client2_ip &> mw2_client2_ping.log &" & 
    ssh $mw2_dns "ping -i 0.2 -c 100 $client3_ip &> mw2_client3_ping.log &" &
    ssh $mw2_dns "ping -i 0.2 -c 100 $server1_ip &> mw2_server1_ping.log &" &
    ssh $mw2_dns "ping -i 0.2 -c 100 $server2_ip &> mw2_server2_ping.log &" &
    ssh $mw2_dns "ping -i 0.2 -c 100 $server3_ip &> mw2_server3_ping.log &" &

    sleep 30

    ssh $mw1_dns "sudo pkill -f ping"
    ssh $mw2_dns "sudo pkill -f ping"

    echo "start pinging finished"
}

function start_memcached_servers {
    echo "start memcached servers ..."

    # stop memcached instance automatically started at startup then start memcached instance in background
    ssh $server1_dns "sudo service memcached stop; memcached -p $server1_port -t 1 &" &
    ssh $server2_dns "sudo service memcached stop; memcached -p $server2_port -t 1 &" &
    ssh $server3_dns "sudo service memcached stop; memcached -p $server3_port -t 1 &" &

    # sleep to be sure memcached servers started completely
    sleep 2

    echo "start memcached servers finished"
}

function populate_memcached_servers {
    echo "start populating memcached servers ..."

    local ratio="1:0"; # set requests

    ssh $client1_dns "./memtier_benchmark-master/memtier_benchmark -s $server1_ip -p $server1_port -n allkeys \
    --protocol=memcache_text --ratio=$ratio --expiry-range=99999-100000 --key-maximum=10000 --hide-histogram \
    --data-size=4096 --key-pattern=S:S"  

    ssh $client2_dns "./memtier_benchmark-master/memtier_benchmark -s $server2_ip -p $server2_port -n allkeys \
    --protocol=memcache_text --ratio=$ratio --expiry-range=99999-100000 --key-maximum=10000 --hide-histogram \
    --data-size=4096 --key-pattern=S:S" 

    ssh $client3_dns "./memtier_benchmark-master/memtier_benchmark -s $server3_ip -p $server3_port -n allkeys \
    --protocol=memcache_text --ratio=$ratio --expiry-range=99999-100000 --key-maximum=10000 --hide-histogram \
    --data-size=4096 --key-pattern=S:S" 
    
    echo "start populating memcached servers finished"
}

function kill_instances_before_experiment {

    # kill instances (may still run)
    ssh $server1_dns "sudo pkill -f memcached" 
    ssh $server2_dns "sudo pkill -f memcached" 
    ssh $server3_dns "sudo pkill -f memcached" 

    ssh $mw1_dns "sudo pkill -f middleware"
    ssh $mw2_dns "sudo pkill -f middleware"

}

function kill_instances {
    echo "start killing instances ..."

    ssh $server1_dns "sudo service memcached stop; sudo pkill -f memcached" 
    ssh $server2_dns "sudo service memcached stop; sudo pkill -f memcached" 
    ssh $server3_dns "sudo service memcached stop; sudo pkill -f memcached" 

    ssh $mw1_dns "sudo pkill -f middleware"
    ssh $mw2_dns "sudo pkill -f middleware"

    echo "start killing instances finished"
}


function compile_uplaod_mw {
    echo "start compile_uplaod_mw ..."

    # compile
    cd $HOME/Desktop/ASL_project/
    ant

    # upload
    scp "$HOME/Desktop/ASL_project/dist/middleware-fmorath.jar" $mw1_dns:
    scp "$HOME/Desktop/ASL_project/dist/middleware-fmorath.jar" $mw2_dns:

    scp "$HOME/Desktop/ASL_project/scripts/4_GetsAndMultigets/aggregate_mw_data.py" $mw1_dns:
    scp "$HOME/Desktop/ASL_project/scripts/4_GetsAndMultigets/aggregate_mw_data.py" $mw2_dns:

    echo "start compile_uplaod_mw finished"
}


function run_experiment {
    echo "run run_experiment ..."

    # log folder setup
    local timestamp=$(date +%Y-%m-%d_%Hh%M)
    mkdir -p "$HOME/Desktop/ASL_project/logs/4_GetsAndMultigets/$timestamp"

    # copy ping logs
    scp $mw1_dns:mw1* "$HOME/Desktop/ASL_project/logs/4_GetsAndMultigets/$timestamp"
    ssh $mw1_dns "rm *.log"

    scp $mw2_dns:mw2* "$HOME/Desktop/ASL_project/logs/4_GetsAndMultigets/$timestamp"
    ssh $mw2_dns "rm *.log"

    # params
    local test_time=60;
    local threads=1 # thread count (CT)
    local ratio_list=(1:3) #(1:1 1:3 1:6 1:9)
    local vc_list=(2) # virtual clients per thread (VC)
    local rep_list=(1) #(1 2 3) 
    local worker_list=(64)
    local sharded_list=(false) #(true false) 

    for sharded in "${sharded_list[@]}"; do
        for ratio in "${ratio_list[@]}"; do
            for worker in "${worker_list[@]}"; do

                for rep in "${rep_list[@]}"; do
                        local vc=2

                        echo "lunch ratio_${ratio}_vc_${vc}_worker_${worker}_rep_${rep}_sharded_${sharded} run"

                        file_ext="ratio_${ratio}_vc_${vc}_worker_${worker}_rep_${rep}_sharded_${sharded}"

                        # middleware 
                        ssh $mw1_dns "java -jar middleware-fmorath.jar -l $mw1_ip -p $mw1_port -m ${server1_ip}:${server1_port} ${server2_ip}:${server2_port} ${server3_ip}:${server3_port} \
                        -t $worker -s $sharded &> /dev/null &" &
                        ssh $mw2_dns "java -jar middleware-fmorath.jar -l $mw2_ip -p $mw2_port -m ${server1_ip}:${server1_port} ${server2_ip}:${server2_port} ${server3_ip}:${server3_port} \
                        -t $worker -s $sharded &> /dev/null &" &
                        sleep 2

                        # memtier connection to mw1
                        ssh $client1_dns "./memtier_benchmark-master/memtier_benchmark -s $mw1_ip -p $mw1_port \
                        --protocol=memcache_text --ratio=$ratio --expiry-range=99999-100000 --key-maximum=10000 --multi-key-get=${ratio: -1}\
                        --clients=$vc --threads=$threads --test-time=$test_time --data-size=4096 --json-out-file=client1_1_${file_ext}_mem.json &> /dev/null &" &  

                        ssh $client2_dns "./memtier_benchmark-master/memtier_benchmark -s $mw1_ip -p $mw1_port \
                        --protocol=memcache_text --ratio=$ratio --expiry-range=99999-100000 --key-maximum=10000 --multi-key-get=${ratio: -1}\
                        --clients=$vc --threads=$threads --test-time=$test_time --data-size=4096 --json-out-file=client2_1_${file_ext}_mem.json &> /dev/null &" & 

                        ssh $client3_dns "./memtier_benchmark-master/memtier_benchmark -s $mw1_ip -p $mw1_port \
                        --protocol=memcache_text --ratio=$ratio --expiry-range=99999-100000 --key-maximum=10000 --multi-key-get=${ratio: -1}\
                        --clients=$vc --threads=$threads --test-time=$test_time --data-size=4096 --json-out-file=client3_1_${file_ext}_mem.json &> /dev/null &" & 

                        # memtier connection to mw2
                        ssh $client1_dns "./memtier_benchmark-master/memtier_benchmark -s $mw2_ip -p $mw2_port \
                        --protocol=memcache_text --ratio=$ratio --expiry-range=99999-100000 --key-maximum=10000 --multi-key-get=${ratio: -1}\
                        --clients=$vc --threads=$threads --test-time=$test_time --data-size=4096 --json-out-file=client1_2_${file_ext}_mem.json &> /dev/null &" &  

                        ssh $client2_dns "./memtier_benchmark-master/memtier_benchmark -s $mw2_ip -p $mw2_port \
                        --protocol=memcache_text --ratio=$ratio --expiry-range=99999-100000 --key-maximum=10000 --multi-key-get=${ratio: -1}\
                        --clients=$vc --threads=$threads --test-time=$test_time --data-size=4096 --json-out-file=client2_2_${file_ext}_mem.json &> /dev/null &" & 

                        ssh $client3_dns "./memtier_benchmark-master/memtier_benchmark -s $mw2_ip -p $mw2_port \
                        --protocol=memcache_text --ratio=$ratio --expiry-range=99999-100000 --key-maximum=10000 --multi-key-get=${ratio: -1}\
                        --clients=$vc --threads=$threads --test-time=$test_time --data-size=4096 --json-out-file=client3_2_${file_ext}_mem.json &> /dev/null &" & 

                        # dstat: cpu, net usage statistics           
                        ssh $client1_dns "dstat -c -n --output dstat_client1_${file_ext}.csv -T 1 $test_time &> /dev/null &" &
                        ssh $mw1_dns "dstat -c -n -d -g -y --output dstat_mw1_${file_ext}.csv -T 1 $test_time &> /dev/null &" &
                        ssh $server1_dns "dstat -c -n --output dstat_server1_${file_ext}.csv -T 1 $test_time &> /dev/null &" &

                        # wait until experiments are finished
                        sleep $(($test_time + 5))

                        # kill middleware
                        ssh $mw1_dns "sudo pkill -f middleware"
                        ssh $mw2_dns "sudo pkill -f middleware"
                        echo "killed mw"
                        sleep 5

                        # run python script to aggregate data
                        echo "aggregate mw data ..."
                        ssh $mw1_dns "python3 aggregate_mw_data.py mw.csv mw1_${file_ext}.csv"
                        ssh $mw2_dns "python3 aggregate_mw_data.py mw.csv mw2_${file_ext}.csv"
                                       
                        # copy data to local file system and delete on vm
                        echo "copy collected data to local FS ..."
                        scp $client1_dns:client* "$HOME/Desktop/ASL_project/logs/4_GetsAndMultigets/$timestamp"
                        scp $client2_dns:client* "$HOME/Desktop/ASL_project/logs/4_GetsAndMultigets/$timestamp"
                        scp $client3_dns:client* "$HOME/Desktop/ASL_project/logs/4_GetsAndMultigets/$timestamp"

                        scp $mw1_dns:mw1* "$HOME/Desktop/ASL_project/logs/4_GetsAndMultigets/$timestamp"
                        scp $mw2_dns:mw2* "$HOME/Desktop/ASL_project/logs/4_GetsAndMultigets/$timestamp"

                        scp $client1_dns:dstat* "$HOME/Desktop/ASL_project/logs/4_GetsAndMultigets/$timestamp"
                        scp $mw1_dns:dstat* "$HOME/Desktop/ASL_project/logs/4_GetsAndMultigets/$timestamp"
                        scp $server1_dns:dstat* "$HOME/Desktop/ASL_project/logs/4_GetsAndMultigets/$timestamp"

                        ssh $client1_dns "rm *.json; rm *.csv"
                        ssh $client2_dns "rm *.json"
                        ssh $client3_dns "rm *.json"
                        ssh $mw1_dns "rm *.csv"
                        ssh $mw2_dns "rm *.csv"
                        ssh $server1_dns "rm *.csv"
                done

            done
        done
    done
            
    echo "run run_experiment finished"
} 



if [ "${1}" == "run" ]; then

   # kill instances that may still run
   kill_instances_before_experiment

   # compile and upload mw
   compile_uplaod_mw

   # start memcached servers
   start_memcached_servers

   # populate memcached servers with key-value pairs
   populate_memcached_servers

   # do ping test one
   ping

   # run experiment one
   run_experiment 

   # kill instances
   kill_instances

fi