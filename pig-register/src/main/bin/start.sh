#!/bin/bash


#----------以下变量可以在脚本中直接使用----------------
# $def_app_id           应用id
# $def_app_name         应用名称
# $def_app_domain       应用域名
# $def_app_deploy_path  兼容老部署,废弃
# $def_path_app_log     应用日志路径 如：/export/Logs/
# $def_path_app_data    如：/export/Data
# $def_group_id         分组 id
# $def_instance_id      实例id
# $def_instance_name    实例名称 server1
# $def_instance_path    实例完成路径 /export/Instances/jone/server1/
# $def_host_ip
#--------------------------
#
set -o errexit
# 获取运行脚本的上级目录
BASEDIR=$(cd $(dirname $0) && pwd)/..

#定义当前应用的名称
readonly APP_NAME="tianwei-register"
# java home
readonly JAVA_HOME="/export/servers/jdk1.8.0_60"
readonly JAVA="$JAVA_HOME/bin/java"
# main 函数所在的类名称。
readonly MAIN_CLASS="com.alibaba.nacos.PigNacosApplication"
readonly LOG_BASE_DIR="/export/Logs/$APP_NAME"
readonly GC_LOG="$LOG_BASE_DIR/gc.log"
readonly ERROR_LOG="$LOG_BASE_DIR/err.log"
mkdir -p $LOG_BASE_DIR

# 获取当前应用的进程ID
function get_pid
{
    pgrep -f "java .*$MAIN_CLASS"
}

#定义启动 jvm 的参数信息。
JVM_OPTS="-server -XX:+PrintGCDetails -XX:+PrintGCDateStamps \
            -Xloggc:$GC_LOG \
            -XX:+HeapDumpOnOutOfMemoryError \
            -XX:ErrorFile=$ERROR_LOG \
            -XX:HeapDumpPath=/export/Logs/$APP_NAME/dump.hprof \
            -Xms6G -Xmx6G -Xmn2G -Xss256k \
            -XX:MaxDirectMemorySize=2G -XX:+ExplicitGCInvokesConcurrent \
            -XX:SurvivorRatio=7 -XX:+UseParNewGC -XX:+UseConcMarkSweepGC \
            -XX:CMSMaxAbortablePrecleanTime=1500 -XX:+CMSParallelRemarkEnabled \
            -XX:+CMSScavengeBeforeRemark -XX:+UseCMSInitiatingOccupancyOnly \
            -XX:CMSInitiatingOccupancyFraction=68 -XX:GCTimeRatio=49"
CLASSPATH="$BASEDIR/conf/:$BASEDIR/lib/*"

[[ -z $(get_pid) ]] || {
    echo "ERROR:  $APP_NAME already running" >&2
    exit 1
}

echo "Starting $APP_NAME ...."
[[ -x $JAVA ]] || {
    echo "ERROR: no executable java found at $JAVA" >&2
    exit 1
}
cd $BASEDIR
setsid "$JAVA" $JVM_OPTS \
    -classpath "$CLASSPATH" \
    -Dbasedir="$BASEDIR" \
    -Dapp.name="$APP_NAME" \
    -Dfile.encoding="UTF-8" \
    $MAIN_CLASS \
    "$@" > /dev/null 2>&1 &

sleep 0.5
[[ -n $(get_pid) ]] || {
    echo "ERROR: $APP_NAME failed to start" >&2
    exit 1
}
echo "$APP_NAME is up running :)"
