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
echo " Docker Compose 项目重启"
echo " 项目目录：$PROJECT_DIR"
echo "=============================="
echo

$DOCKER compose restart

echo
echo "等待服务恢复..."
sleep 10

echo
echo "当前容器状态："
$DOCKER compose ps

echo
echo "执行巡检脚本："
./scripts/check.sh

echo "=============================="
echo " 项目重启完成"
echo "=============================="
