#!/bin/bash

set -o errexit
set -o nounset

readonly SELF_DIR=$(cd $(dirname $0) && pwd)
readonly MAIN_CLASS="com.alibaba.nacos.PigNacosApplication"

# 获取当前应用的进程ID
function get_pid
{
    pgrep -f "java .*$MAIN_CLASS"
}

function stop
{
    local -i timeout=20
    local -i interval=1
    local -r service_pid=$(get_pid) || true # ignore error
    [[ -n $service_pid ]] || {
        echo "WARNING: process not found, nothing to stop" >&2
        exit 0
    }
    kill $service_pid
    while (( timeout > 0 )) && get_pid > /dev/null; do
        echo -n "."ƒ
        sleep $interval
        timeout=$(( timeout - interval ))
    done
    if get_pid > /dev/null; then
        echo "WARNING: process still alive, sending SIGKILL ..." >&2
        kill -9 "$service_pid"
    fi
}
function main
{
    get_pid > /dev/null || {
        echo "WARNING: process not found, nothing to stop" >&2
        exit 0  # Ignore error
    }
    stop
}
main "$@"