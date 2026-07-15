#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

if [ "$(id -u)" -eq 0 ]; then
    DOCKER="docker"
else
    DOCKER="sudo docker"
fi

cd "$PROJECT_DIR" || exit 1

echo "=============================="
echo " Docker Compose 项目停止"
echo " 项目目录：$PROJECT_DIR"
echo "=============================="
echo

$DOCKER compose stop

echo
echo "当前容器状态："
$DOCKER compose ps -a

echo
echo "项目已停止。"
echo "注意：stop 只停止容器，不删除 MySQL 数据。"

echo "=============================="
echo " 项目停止完成"
echo "=============================="
