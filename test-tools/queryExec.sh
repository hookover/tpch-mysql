#!/bin/bash

# 数据库配置信息
target_db_ip=`cat config.properties|grep "target_db_ip"|cut -d"=" -f2`
target_db_port=`cat config.properties|grep "target_db_port"|cut -d"=" -f2`
target_db_user=`cat config.properties|grep "target_db_user"|cut -d"=" -f2`
target_db_password=`cat config.properties|grep "target_db_password"|cut -d"=" -f2`
target_db_name=`cat config.properties|grep "target_db_name"|cut -d"=" -f2`
output_file="res.txt"

TEST_TOOLS_HOME=`pwd`;
dbURL="-h $target_db_ip -P $target_db_port  -u$target_db_user"
if [ -z $target_db_password ];
then
  echo URL=$dbURL
else
  dbURL=$dbURL" -p$target_db_password"
  echo URL=$dbURL
fi

# arg1=start, arg2=end, format: %s.%N
function getTiming() {
    start=$1
    end=$2
    start_s=$(echo $start | cut -d '.' -f 1)
    start_ns=$(echo $start | cut -d '.' -f 2)
    end_s=$(echo $end | cut -d '.' -f 1)
    end_ns=$(echo $end | cut -d '.' -f 2)
    time=$(( ( $end_s - $start_s ) * 1000 + ( $end_ns / 1000000 - $start_ns / 1000000 ) ))
    time_s=$(( $time / 1000 ))

    echo "$time ms, $time_s s"
}
    echo "===================================测试开始===================================" >> ${output_file}

for((i=1;i<=22;i++));
do
    echo "============================================================================"
    start=$(date +%s.%N)
    mysql $dbURL  --local-infile=1 -D $target_db_name < $TEST_TOOLS_HOME/queries/$i.sql
    end=$(date +%s.%N)
    echo $i sql runtime `getTiming $start $end`
    echo $i sql runtime `getTiming $start $end` >> ${output_file}
done



