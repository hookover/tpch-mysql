#!/bin/sh

LS_PATH_STRING=$1
GP_TPCH_HOME=`readlink -f .`
SQL_DATA=$GP_TPCH_HOME

if [ ! -n "$LS_PATH_STRING" ] ;then
    echo "必须输入文件路径，如:data/*.tpl"
    exit 1
fi

target_db_asynchronous=`cat config.properties|grep "target_db_asynchronous"|cut -d"=" -f2`
target_db_delete=`cat config.properties|grep "target_db_delete"|cut -d"=" -f2`

# 数据库配置信息
target_db_ip=`cat config.properties|grep "target_db_ip"|cut -d"=" -f2`
target_db_port=`cat config.properties|grep "target_db_port"|cut -d"=" -f2`
target_db_user=`cat config.properties|grep "target_db_user"|cut -d"=" -f2`
target_db_password=`cat config.properties|grep "target_db_password"|cut -d"=" -f2`
target_db_name=`cat config.properties|grep "target_db_name"|cut -d"=" -f2`

# 优化
# https://mariadb.com/kb/en/library/how-to-quickly-insert-data-into-mariadb/

# 命令行
# SET @@session.unique_checks = 0;
# SET @@session.foreign_key_checks = 0;

# my.cnf
# max_length_for_sort_data = 1024000
#  secure_file_priv=/data
#  innodb_autoinc_lock_mode=2
#  wait_timeout=2880000
#  interactive_timeout = 2880000
#  max_allowed_packet=1024M

# arg1=start, arg2=end, format: %s.%N
function getTiming() {
    start=$1
    end=$2
    start_s=$(echo $start | cut -d '.' -f 1)
    start_ns=$(echo $start | cut -d '.' -f 2)
    end_s=$(echo $end | cut -d '.' -f 1)
    end_ns=$(echo $end | cut -d '.' -f 2)
    time=$(( ( 10#$end_s - 10#$start_s ) * 1000 + ( 10#$end_ns / 1000000 - 10#$start_ns / 1000000 ) ))
    echo "$time ms"
}


TEST_TOOLS_HOME=`pwd`;
dbURL="-h $target_db_ip -P $target_db_port  -u$target_db_user"
if [ -z $target_db_password ];
then
  echo URL=$dbURL
else
  dbURL=$dbURL" -p$target_db_password"
  echo URL=$dbURL
fi


i=0
for tbl in `ls $LS_PATH_STRING`; do
    let i=i+1
    tbl_path=$(echo "$SQL_DATA/$tbl") #mysql 区别大小写
    echo mysqlimport $dbURL  --fields-terminated-by="|" $target_db_name $tbl_path

    let n=i%2

    if [ $n -eq 0 ]; then
        echo "$i 重启 mysqld"
        sudo service mysqld restart
    fi

    #mysqlimport -h 127.0.0.1 -P 3306 -uroot -p'BzU!fg/pt7o5' tpch --fields-terminated-by="|"  /data/bigdata/tpch-mysql/test-tools/impdata/orders.xaa.tbl

    start=$(date +%s.%N)
	mysqlimport $dbURL $target_db_name --fields-terminated-by='|' $tbl_path
	end=$(date +%s.%N)
	echo $path `getTiming $start $end`
done