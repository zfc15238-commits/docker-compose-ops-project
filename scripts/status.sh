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
echo " Docker Compose 项目状态"
echo " 项目目录：$PROJECT_DIR"
echo "=============================="
echo

echo "【1】容器状态"
$DOCKER compose ps -a
echo

echo "【2】最近生成的 MySQL 备份文件"
ls -lh backups/mysql/*.sql 2>/dev/null | tail -5
echo

echo "【3】最近巡检日志"
tail -30 logs/check.log 2>/dev/null
echo

echo "=============================="
echo " 状态查看完成"
echo "=============================="
