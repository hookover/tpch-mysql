#!/bin/bash

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



#创建数据库
if [ "0" -eq "$target_db_delete" ];
then
echo "delete db $target_db_name"
mysql $dbURL -D test<<EOF
DROP DATABASE IF  EXISTS $target_db_name;
EOF
fi

echo "crate db $target_db_name"
mysql $dbURL -D test<<EOF
CREATE DATABASE IF NOT EXISTS $target_db_name;
EOF

# 创建表
echo "crate tables"
mysql $dbURL -D $target_db_name<$TEST_TOOLS_HOME/initdb/dss.sql

# 导入数据
echo "import datas"


if [ "0" -eq "$target_db_asynchronous" ];
then
    echo "import data target_db_asynchronous"
	nohup mysqlimport $dbURL  --fields-terminated-by="|" $target_db_name < $TEST_TOOLS_HOME/impdata/customer.tpl&
	nohup mysqlimport $dbURL  --fields-terminated-by="|" $target_db_name < $TEST_TOOLS_HOME/impdata/lineitem.tpl&
	nohup mysqlimport $dbURL  --fields-terminated-by="|" $target_db_name < $TEST_TOOLS_HOME/impdata/part.tpl&
	nohup mysqlimport $dbURL  --fields-terminated-by="|" $target_db_name < $TEST_TOOLS_HOME/impdata/nation.tpl&
	nohup mysqlimport $dbURL  --fields-terminated-by="|" $target_db_name < $TEST_TOOLS_HOME/impdata/orders.tpl&
	nohup mysqlimport $dbURL  --fields-terminated-by="|" $target_db_name < $TEST_TOOLS_HOME/impdata/partsupp.tpl&
	nohup mysqlimport $dbURL  --fields-terminated-by="|" $target_db_name < $TEST_TOOLS_HOME/impdata/region.tpl&
	nohup mysqlimport $dbURL  --fields-terminated-by="|" $target_db_name < $TEST_TOOLS_HOME/impdata/supplier.tpl&
	echo "import data target_db_asynchronous running"
else
	start=$(date +%s.%N)
	mysqlimport $dbURL  --fields-terminated-by="|" $target_db_name < $TEST_TOOLS_HOME/impdata/nation.tpl
	end=$(date +%s.%N)
	echo import NATION.sql end in `getTiming $start $end`

    start=$(date +%s.%N)
	mysqlimport $dbURL  --fields-terminated-by="|" $target_db_name < $TEST_TOOLS_HOME/impdata/part.tpl
	end=$(date +%s.%N)
	echo import PART.sql end in `getTiming $start $end`

	start=$(date +%s.%N)
	mysqlimport $dbURL  --fields-terminated-by="|" $target_db_name < $TEST_TOOLS_HOME/impdata/region.tpl
	end=$(date +%s.%N)
	echo import REGION.sql end in `getTiming $start $end`

    start=$(date +%s.%N)
    mysqlimport $dbURL  --fields-terminated-by="|" $target_db_name < $TEST_TOOLS_HOME/impdata/customer.tpl
    end=$(date +%s.%N)
    echo import CUSTOMER.sql end in `getTiming $start $end`

	start=$(date +%s.%N)
	mysqlimport $dbURL  --fields-terminated-by="|" $target_db_name < $TEST_TOOLS_HOME/impdata/orders.tpl
	end=$(date +%s.%N)
	echo import ORDERS.sql end in `getTiming $start $end`

	start=$(date +%s.%N)
	mysqlimport $dbURL  --fields-terminated-by="|" $target_db_name < $TEST_TOOLS_HOME/impdata/supplier.tpl
	end=$(date +%s.%N)
	echo import SUPPLIER.sql end in `getTiming $start $end`

	start=$(date +%s.%N)
	mysqlimport $dbURL  --fields-terminated-by="|" $target_db_name < $TEST_TOOLS_HOME/impdata/partsupp.tpl
	end=$(date +%s.%N)
	echo import PARTSUPP.sql end in `getTiming $start $end`

    start=$(date +%s.%N)
	mysqlimport $dbURL  --fields-terminated-by="|" $target_db_name < $TEST_TOOLS_HOME/impdata/lineitem.tpl
	end=$(date +%s.%N)
	echo import LINEITEM.sql end in `getTiming $start $end`

fi


