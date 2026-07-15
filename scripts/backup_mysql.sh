#!/bin/bash

# 自动识别项目目录
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# 备份目录
BACKUP_DIR="$PROJECT_DIR/backups/mysql"

# 数据库配置
DB_CONTAINER="mysql-compose"
DB_NAME="compose_test"
DB_USER="root"
DB_PASSWORD="123456"

# 当前时间，用于生成备份文件名
TIME=$(date '+%Y%m%d_%H%M%S')

# 备份文件名
BACKUP_FILE="$BACKUP_DIR/${DB_NAME}_${TIME}.sql"

# 如果是 root 执行，就直接用 docker
# 如果是普通用户执行，就用 sudo docker
if [ "$(id -u)" -eq 0 ]; then
    DOCKER="docker"
else
    DOCKER="sudo docker"
fi

echo "=============================="
echo " MySQL 数据库备份开始"
echo " 备份时间：$(date '+%Y-%m-%d %H:%M:%S')"
echo " 项目目录：$PROJECT_DIR"
echo " 数据库名：$DB_NAME"
echo " 备份文件：$BACKUP_FILE"
echo "=============================="
echo

# 创建备份目录
mkdir -p "$BACKUP_DIR"

# 执行备份
if $DOCKER exec "$DB_CONTAINER" mysqldump -u"$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" > "$BACKUP_FILE"; then
    echo "数据库备份成功"
    echo "备份文件：$BACKUP_FILE"
    echo

    echo "备份文件大小："
    ls -lh "$BACKUP_FILE"
    echo

    echo "备份文件前几行："
    head "$BACKUP_FILE"
    echo

    echo "=============================="
    echo " MySQL 数据库备份完成"
    echo "=============================="
    exit 0
else
    echo "数据库备份失败"
    echo "请检查 MySQL 容器是否运行、数据库名是否正确、密码是否正确"
    echo "=============================="
    echo " MySQL 数据库备份失败"
    echo "=============================="
    exit 1
fi
