# Docker Compose 三容器项目故障排查 SOP

## 一、项目访问链路

本项目由三个核心容器组成：

   Nginx
   Python Flask App
   MySQL

完整访问链路：

   用户访问 localhost:8082/api/users
      ↓
   Nginx 容器
      ↓
   Python Flask App 容器
      ↓
   MySQL 容器
      ↓
   compose_test.compose_users 表
      ↓
   返回 JSON 数据

所以排查故障时，也要按照这个顺序判断：

   Nginx -> App -> MySQL


---

## 二、通用排查入口

### 1. 先查看容器状态

   sudo docker compose ps -a

重点看：

   Up：容器正在运行
   Exited：容器已经停止
   healthy：健康检查正常
   unhealthy：健康检查失败


### 2. 执行一键巡检脚本

   ./scripts/check.sh

如果最终显示：

   巡检结果：通过，当前项目运行正常

说明项目整体正常。

如果显示：

   巡检结果：失败，请检查上方异常项

就根据异常项继续排查。


### 3. 查看项目状态脚本

   ./scripts/status.sh

该脚本可以快速查看：

   容器状态
   最近备份文件
   最近巡检日志


---

## 三、故障场景 1：访问 /api/users 出现 502

### 1. 故障现象

访问：

   curl -i http://localhost:8082/api/users

返回：

   502 Bad Gateway


### 2. 基本判断

502 一般说明：

   Nginx 收到了请求，但是无法连接后端 App。

问题多数出在：

   Nginx -> App 这一层


### 3. 常见原因

1. App 容器停止
2. App 服务端口错误
3. Nginx proxy_pass 配置错误
4. Docker 网络异常
5. Nginx 无法解析 app 服务名


### 4. 排查命令

查看容器状态：

   sudo docker compose ps -a

查看 Nginx 日志：

   sudo docker compose logs nginx

测试 Nginx 容器访问 App：

   sudo docker exec nginx-compose curl http://app:5000/health

查看 Nginx 配置：

   grep -R "proxy_pass" -n .


### 5. 重点日志关键词

   connect() failed
   connection refused
   upstream
   host not found


### 6. 恢复方法

如果 App 停止：

   sudo docker compose start app

如果 Nginx 配置端口写错：

   nano nginx-conf/default.conf

确认配置为：

   proxy_pass http://app:5000/;

然后重启 Nginx：

   sudo docker compose restart nginx

最后验证：

   curl http://localhost:8082/api/users


---

## 四、故障场景 2：访问 /api/users 出现 500

### 1. 故障现象

访问：

   curl -i http://localhost:8082/api/users

返回：

   500 Internal Server Error


### 2. 基本判断

500 一般说明：

   请求已经到达 App，但是 App 内部处理失败。

问题多数出在：

   App 内部
   App -> MySQL 这一层


### 3. 常见原因

1. MySQL 容器停止
2. App 连接不上 MySQL
3. Python 依赖缺失
4. SQL 执行失败
5. App 代码异常


### 4. 排查命令

查看容器状态：

   sudo docker compose ps -a

查看 App 日志：

   sudo docker compose logs app

测试 App 直连接口：

   curl -i http://localhost:5000/users

测试 App 到 MySQL 端口：

   sudo docker exec python-app-compose python -c "import socket; s=socket.socket(); s.settimeout(3); s.connect(('mysql',3306)); print('mysql port ok'); s.close()"


### 5. 重点日志关键词

   pymysql
   OperationalError
   Traceback
   Can't connect to MySQL server
   Connection refused
   ModuleNotFoundError


### 6. 恢复方法

如果 MySQL 停止：

   sudo docker compose start mysql

等待 MySQL 恢复 healthy：

   sudo docker compose ps

如果是 Python 依赖缺失，例如缺少 cryptography：

   nano app/requirements.txt

增加：

   cryptography

重新构建 App：

   sudo docker compose up -d --build app

最后验证：

   curl http://localhost:5000/users
   curl http://localhost:8082/api/users


---

## 五、故障场景 3：App 显示 unhealthy

### 1. 故障现象

执行：

   sudo docker compose ps

看到：

   python-app-compose   Up (unhealthy)


### 2. 基本判断

unhealthy 表示：

   容器还在运行，但是 Docker 健康检查失败。

注意：

   unhealthy 不一定代表业务完全不可用。
   它只说明 healthcheck 配置的检查条件没有通过。


### 3. 常见原因

1. healthcheck 路径写错
2. healthcheck 端口写错
3. /health 接口异常
4. 容器内部没有 curl
5. 服务刚启动，还没完全恢复


### 4. 排查命令

查看容器状态：

   sudo docker compose ps

查看健康检查详情：

   sudo docker inspect python-app-compose | grep -A 30 Health

测试健康接口：

   curl http://localhost:5000/health

进入 App 容器内部测试：

   sudo docker exec python-app-compose curl http://localhost:5000/health


### 5. 恢复方法

检查 docker-compose.yml 中的 healthcheck：

   nano docker-compose.yml

确认配置类似：

   healthcheck:
     test: ["CMD", "curl", "-f", "http://localhost:5000/health"]
     interval: 10s
     timeout: 5s
     retries: 3

修改后重建 App：

   sudo docker compose up -d --force-recreate app

最后查看：

   sudo docker compose ps


---

## 六、故障场景 4：MySQL 容器 Exited

### 1. 故障现象

执行：

   sudo docker compose ps -a

看到：

   mysql-compose   Exited


### 2. 影响

MySQL 停止后：

   App 查询数据库失败
   /users 返回 500
   /api/users 也返回 500


### 3. 排查命令

查看 MySQL 日志：

   sudo docker compose logs mysql

查看 App 日志：

   sudo docker compose logs app

测试 MySQL 是否恢复：

   sudo docker compose ps


### 4. 恢复方法

启动 MySQL：

   sudo docker compose start mysql

等待 10 秒：

   sleep 10

查看状态：

   sudo docker compose ps

执行巡检：

   ./scripts/check.sh


---

## 七、故障场景 5：cron 定时巡检不执行

### 1. 故障现象

等待 5 分钟后，日志没有新增：

   tail -80 logs/check.log
   tail -80 logs/cron.log


### 2. 排查定时任务

因为本项目的定时任务放在 root crontab 中，所以查看：

   sudo crontab -l

确认存在：

   */5 * * * * cd /home/zfc/compose-study && /bin/bash scripts/check.sh >> logs/cron.log 2>&1


### 3. 排查 cron 服务

查看 cron 服务状态：

   sudo systemctl status cron

如果没有运行：

   sudo systemctl start cron

设置开机自启：

   sudo systemctl enable cron


### 4. 常见问题

普通用户 crontab 执行带 sudo 的脚本，可能出现：

   sudo: a terminal is required to read the password
   sudo: a password is required

解决方法：

   使用 sudo crontab -e
   把任务放到 root crontab 中执行


---

## 八、故障场景 6：备份或恢复失败

### 1. 备份脚本

执行：

   ./scripts/backup_mysql.sh

如果失败，重点检查：

1. MySQL 容器是否运行
2. 数据库名是否正确
3. 数据库密码是否正确
4. backups/mysql 目录是否存在


### 2. 恢复脚本

执行格式：

   ./scripts/restore_mysql.sh backups/mysql/备份文件名.sql

如果不传参数，脚本会提示用法。

查找最新备份：

   ls -t backups/mysql/*.sql | head -1


### 3. 恢复后验证

恢复后必须验证数据库和接口：

   sudo docker exec -it mysql-compose mysql -uroot -p123456 -e "USE compose_test; SELECT * FROM compose_users;"

   curl http://localhost:5000/users

   curl http://localhost:8082/api/users


---

## 九、常用恢复顺序

如果项目整体异常，可以按这个顺序恢复：

### 1. 查看状态

   ./scripts/status.sh

### 2. 执行巡检

   ./scripts/check.sh

### 3. 查看日志

   sudo docker compose logs app
   sudo docker compose logs nginx
   sudo docker compose logs mysql

### 4. 重启项目

   ./scripts/restart.sh

### 5. 如果重启后仍然异常

重新启动全部服务：

   sudo docker compose up -d

### 6. 如果 App 依赖或镜像有变化

重新构建 App：

   sudo docker compose up -d --build app

### 7. 最终验证

   curl http://localhost:5000/users
   curl http://localhost:8082/api/users
   ./scripts/check.sh


---

## 十、故障判断口诀

502：

   Nginx 找不到 App。

500：

   请求到了 App，但 App 内部出错，常见是数据库连接失败。

unhealthy：

   容器还在，但健康检查没通过。

Exited：

   容器已经停止。

Nginx -> App 正常，但 App -> MySQL 异常：

   问题大概率在数据库层。

App 直连正常，但 Nginx 代理异常：

   问题大概率在 Nginx 代理层。


---

## 十一、本 SOP 总结

本 SOP 用于记录 Docker Compose 三容器项目的常见故障排查流程。

项目核心排查思路是：

   先看容器状态
   再看访问链路
   再看服务日志
   再做接口验证
   最后执行恢复操作

本项目的核心链路是：

   Nginx -> Python App -> MySQL

所以排查时也按这条链路逐层定位问题。
