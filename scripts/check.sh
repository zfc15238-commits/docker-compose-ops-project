#!/bin/bash

# 自动识别项目目录
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

LOG_DIR="$PROJECT_DIR/logs"
LOG_FILE="$LOG_DIR/check.log"

mkdir -p "$LOG_DIR"

# 如果是 root 执行，就直接用 docker
# 如果是普通用户执行，就用 sudo docker
if [ "$(id -u)" -eq 0 ]; then
    DOCKER="docker"
else
    DOCKER="sudo docker"
fi

main() {
    ERROR=0

    cd "$PROJECT_DIR" || {
        echo "无法进入项目目录：$PROJECT_DIR"
        return 1
    }

    echo "=============================="
    echo " Docker Compose 项目巡检开始"
    echo " 巡检时间：$(date '+%Y-%m-%d %H:%M:%S')"
    echo " 项目目录：$PROJECT_DIR"
    echo "=============================="
    echo

    echo "【1】查看所有容器状态"
    $DOCKER compose ps -a
    echo

    echo "【2】查看 App 重启次数"
    if $DOCKER inspect -f 'python-app-compose RestartCount={{.RestartCount}} Status={{.State.Status}} RestartPolicy={{.HostConfig.RestartPolicy.Name}}' python-app-compose; then
        echo "App 重启信息获取正常"
    else
        echo "App 重启信息获取失败"
        ERROR=1
    fi
    echo

    echo "【3】测试 App 直连接口"
    if curl -fsS http://localhost:5000/users > /dev/null; then
        echo "App 接口正常：http://localhost:5000/users"
    else
        echo "App 接口异常：http://localhost:5000/users"
        ERROR=1
    fi
    echo

    echo "【4】测试 Nginx 代理接口"
    if curl -fsS http://localhost:8082/api/users > /dev/null; then
        echo "Nginx 代理接口正常：http://localhost:8082/api/users"
    else
        echo "Nginx 代理接口异常：http://localhost:8082/api/users"
        ERROR=1
    fi
    echo

    echo "【5】测试 Nginx 容器访问 App"
    if $DOCKER exec nginx-compose curl -fsS http://app:5000/health > /dev/null; then
        echo "Nginx -> App 网络正常"
    else
        echo "Nginx -> App 网络异常"
        ERROR=1
    fi
    echo

    echo "【6】测试 App 容器访问 MySQL 端口"
    if $DOCKER exec python-app-compose python -c "import socket; s=socket.socket(); s.settimeout(3); s.connect(('mysql',3306)); print('mysql port ok'); s.close()" > /dev/null; then
        echo "App -> MySQL 网络正常"
    else
        echo "App -> MySQL 网络异常"
        ERROR=1
    fi
    echo

    echo "=============================="
    if [ $ERROR -eq 0 ]; then
        echo "巡检结果：通过，当前项目运行正常"
    else
        echo "巡检结果：失败，请检查上方异常项"
    fi
    echo " Docker Compose 项目巡检结束"
    echo "=============================="
    echo

    return $ERROR
}

main 2>&1 | tee -a "$LOG_FILE"
exit ${PIPESTATUS[0]}
