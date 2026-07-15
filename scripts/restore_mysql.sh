#!/bin/bash

# 自动识别项目目录
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# 数据库配置
DB_CONTAINER="mysql-compose"
DB_NAME="compose_test"
DB_USER="root"
DB_PASSWORD="123456"

# 如果是 root 执行，就直接用 docker
# 如果是普通用户执行，就用 sudo docker
if [ "$(id -u)" -eq 0 ]; then
    DOCKER="docker"
else
    DOCKER="sudo docker"
fi

# 获取用户传入的备份文件
RESTORE_FILE="$1"

echo "=============================="
echo " MySQL 数据库恢复脚本"
echo " 当前时间：$(date '+%Y-%m-%d %H:%M:%S')"
echo " 项目目录：$PROJECT_DIR"
echo " 数据库名：$DB_NAME"
echo "=============================="
echo

# 如果没有传入备份文件，就提示用法
if [ -z "$RESTORE_FILE" ]; then
    echo "未指定备份文件"
    echo
    echo "用法："
    echo "  ./scripts/restore_mysql.sh backups/mysql/备份文件名.sql"
    echo
    echo "当前可用备份文件："
    ls -lh "$PROJECT_DIR/backups/mysql/"*.sql 2>/dev/null
    echo
    exit 1
fi

# 如果传入的是相对路径，转换成项目目录下的路径
if [[ "$RESTORE_FILE" != /* ]]; then
    RESTORE_FILE="$PROJECT_DIR/$RESTORE_FILE"
fi

# 检查备份文件是否存在
if [ ! -f "$RESTORE_FILE" ]; then
    echo "备份文件不存在：$RESTORE_FILE"
    exit 1
fi

echo "准备恢复备份文件："
echo "$RESTORE_FILE"
echo

echo "注意：恢复数据库会把备份文件中的数据导入到当前数据库。"
echo "确认要继续恢复请输入 YES："
read CONFIRM

if [ "$CONFIRM" != "YES" ]; then
    echo "已取消恢复操作"
    exit 1
fi

echo
echo "开始恢复数据库..."

if $DOCKER exec -i "$DB_CONTAINER" mysql -u"$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" < "$RESTORE_FILE"; then
    echo
    echo "数据库恢复成功"
    echo

    echo "恢复后数据如下："
    $DOCKER exec "$DB_CONTAINER" mysql -u"$DB_USER" -p"$DB_PASSWORD" -e "USE $DB_NAME; SELECT * FROM compose_users;"
    echo

    echo "=============================="
    echo " MySQL 数据库恢复完成"
    echo "=============================="
    exit 0
else
    echo
    echo "数据库恢复失败"
    echo "请检查 MySQL 容器是否运行、备份文件是否正确、数据库密码是否正确"
    echo "=============================="
    echo " MySQL 数据库恢复失败"
    echo "=============================="
    exit 1
fi
