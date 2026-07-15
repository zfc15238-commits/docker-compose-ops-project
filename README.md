# 基于 Docker Compose 的 Nginx + Flask + MySQL 容器化部署项目

## 一、项目简介

本项目是一个基于 Docker Compose 的三容器部署项目，使用 Docker Compose 统一编排 Nginx、Python Flask App 和 MySQL 服务。

项目实现了：

- Nginx 反向代理后端接口
- Flask App 提供 Web API 服务
- MySQL 保存业务数据
- App 通过 PyMySQL 连接 MySQL
- MySQL 数据持久化
- 服务健康检查
- 容器异常自动重启
- 故障演练与日志排查
- 巡检脚本与 cron 定时巡检
- MySQL 数据库备份与恢复
- 一键启动、停止、重启和状态查看脚本

本项目主要用于学习 Docker、Docker Compose、Nginx、MySQL、Shell 脚本和基础运维排查流程。

---

## 二、项目架构

项目访问链路如下：

```text
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
```

服务说明：

```text
nginx-compose        Nginx 反向代理入口
python-app-compose   Python Flask 后端服务
mysql-compose        MySQL 数据库服务
```

---

## 三、项目目录结构

```text
compose-study
├── docker-compose.yml
├── README.md
├── app
│   ├── app.py
│   ├── requirements.txt
│   └── Dockerfile
├── nginx-conf
│   └── default.conf
├── scripts
│   ├── check.sh
│   ├── backup_mysql.sh
│   ├── restore_mysql.sh
│   ├── start.sh
│   ├── stop.sh
│   ├── restart.sh
│   └── status.sh
├── backups
│   └── mysql
├── logs
│   ├── check.log
│   └── cron.log
└── docs
    └── troubleshooting_sop.md
```

---

## 四、技术栈

```text
Linux
Docker
Docker Compose
Nginx
Python Flask
MySQL
PyMySQL
Shell Script
Cron
```

---

## 五、核心配置说明

### 1. Nginx 反向代理

Nginx 配置文件：

```bash
nginx-conf/default.conf
```

核心配置：

```nginx
location /api/ {
    proxy_pass http://app:5000/;
}
```

说明：

```text
用户访问 localhost:8082/api/users
Nginx 会将请求转发到 app:5000/users
```

其中：

```text
app 是 docker-compose.yml 中 Flask 服务的服务名
5000 是 Flask App 容器内部端口
```

---

### 2. Flask App 连接 MySQL

Flask App 中连接数据库时使用：

```python
host="mysql"
port=3306
```

说明：

```text
mysql 是 docker-compose.yml 中 MySQL 服务的服务名，不是 localhost。
```

因为 Flask App 和 MySQL 分别运行在不同容器中，所以容器之间通过 Compose 服务名通信。

---

### 3. MySQL 数据持久化

MySQL 数据挂载到宿主机目录：

```text
/home/zfc/compose-mysql-data:/var/lib/mysql
```

作用：

```text
即使 MySQL 容器删除或重建，数据库数据仍然保存在宿主机目录中。
```

---

### 4. 健康检查 healthcheck

App 服务配置了健康检查：

```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:5000/health"]
  interval: 10s
  timeout: 5s
  retries: 3
```

作用：

```text
判断 App 容器内部服务是否真正可用。
```

---

### 5. 自动重启 restart

服务配置了：

```yaml
restart: always
```

作用：

```text
当容器异常退出时，Docker 会尝试自动重启容器。
```

---

## 六、启动项目

### 方式一：使用一键启动脚本

```bash
./scripts/start.sh
```

脚本会自动执行：

```text
启动 Docker Compose 项目
等待服务启动
查看容器状态
执行巡检脚本
```

### 方式二：手动启动

```bash
sudo docker compose up -d
```

---

## 七、查看项目状态

使用状态脚本：

```bash
./scripts/status.sh
```

该脚本会查看：

```text
容器状态
最近 MySQL 备份文件
最近巡检日志
```

也可以手动查看：

```bash
sudo docker compose ps
```

---

## 八、接口测试

### 1. 测试 Flask App 直连接口

```bash
curl http://localhost:5000/users
```

### 2. 测试 Nginx 代理接口

```bash
curl http://localhost:8082/api/users
```

如果返回数据库数据，说明完整链路正常：

```text
Nginx -> Flask App -> MySQL
```

### 3. 测试健康接口

```bash
curl http://localhost:5000/health
```

正常输出：

```text
app is running
```

---

## 九、常用运维脚本

所有脚本都在：

```bash
scripts/
```

### 1. 一键启动项目

```bash
./scripts/start.sh
```

### 2. 一键停止项目

```bash
./scripts/stop.sh
```

说明：

```text
stop.sh 使用 docker compose stop，只停止容器，不删除数据。
```

### 3. 一键重启项目

```bash
./scripts/restart.sh
```

### 4. 一键查看状态

```bash
./scripts/status.sh
```

### 5. 一键巡检

```bash
./scripts/check.sh
```

巡检内容包括：

```text
容器状态
App 重启次数
App 直连接口
Nginx 代理接口
Nginx -> App 网络
App -> MySQL 网络
```

---

## 十、MySQL 数据库备份与恢复

### 1. 自动备份数据库

执行：

```bash
./scripts/backup_mysql.sh
```

备份文件保存到：

```bash
backups/mysql/
```

备份文件名示例：

```text
compose_test_20260708_191015.sql
```

### 2. 查看最新备份文件

```bash
ls -t backups/mysql/*.sql | head -1
```

### 3. 恢复数据库

执行：

```bash
./scripts/restore_mysql.sh backups/mysql/备份文件名.sql
```

示例：

```bash
./scripts/restore_mysql.sh backups/mysql/compose_test_20260708_191015.sql
```

恢复时需要输入：

```text
YES
```

用于确认恢复操作。

### 4. 恢复后验证

```bash
curl http://localhost:5000/users
curl http://localhost:8082/api/users
```

如果两个接口都能正常返回数据，说明数据库恢复成功，完整业务链路正常。

---

## 十一、cron 定时巡检

项目配置过 root crontab 定时巡检任务。

查看 root 定时任务：

```bash
sudo crontab -l
```

定时任务示例：

```cron
*/5 * * * * cd /home/zfc/compose-study && /bin/bash scripts/check.sh >> logs/cron.log 2>&1
```

含义：

```text
每 5 分钟自动执行一次 check.sh，并把执行结果写入日志。
```

查看巡检日志：

```bash
tail -80 logs/check.log
tail -80 logs/cron.log
```

---

## 十二、故障排查文档

故障排查 SOP 文档路径：

```bash
docs/troubleshooting_sop.md
```

文档中整理了常见问题：

```text
/api/users 返回 502
/api/users 返回 500
App 显示 unhealthy
MySQL 容器 Exited
cron 定时巡检不执行
备份或恢复失败
```

---

## 十三、常见故障判断

### 1. 502 Bad Gateway

含义：

```text
Nginx 收到了请求，但是无法连接后端 App。
```

常见原因：

```text
App 容器停止
Nginx proxy_pass 写错
App 端口错误
Docker 网络异常
```

### 2. 500 Internal Server Error

含义：

```text
请求已经到达 App，但是 App 内部处理失败。
```

常见原因：

```text
MySQL 停止
App 连接不上 MySQL
Python 依赖缺失
SQL 执行失败
```

### 3. unhealthy

含义：

```text
容器还在运行，但是健康检查失败。
```

常见原因：

```text
healthcheck 路径写错
healthcheck 端口写错
/health 接口异常
服务未完全启动
```

### 4. Exited

含义：

```text
容器已经停止，需要查看日志并重新启动。
```

---

## 十四、常用排查命令

查看容器状态：

```bash
sudo docker compose ps -a
```

查看 App 日志：

```bash
sudo docker compose logs app
```

查看 Nginx 日志：

```bash
sudo docker compose logs nginx
```

查看 MySQL 日志：

```bash
sudo docker compose logs mysql
```

查看健康检查详情：

```bash
sudo docker inspect python-app-compose | grep -A 30 Health
```

测试 Nginx 容器访问 App：

```bash
sudo docker exec nginx-compose curl http://app:5000/health
```

测试 App 容器连接 MySQL：

```bash
sudo docker exec python-app-compose python -c "import socket; s=socket.socket(); s.settimeout(3); s.connect(('mysql',3306)); print('mysql port ok'); s.close()"
```

---

## 十五、项目亮点

1. 使用 Docker Compose 编排 Nginx、Flask App、MySQL 三个容器服务。
2. 使用 Dockerfile 构建 Flask 后端镜像。
3. 使用 Nginx 实现反向代理，将 `/api` 请求转发到后端 App。
4. 使用 Docker 自定义网络实现容器间服务名通信。
5. 使用 volume 挂载实现 MySQL 数据持久化。
6. 配置 healthcheck 判断 App 服务健康状态。
7. 配置 restart: always 提高容器异常退出后的恢复能力。
8. 完成 App、MySQL、Nginx、网络等多种故障演练。
9. 编写 check.sh 巡检脚本，实现一键检查项目状态。
10. 配置 cron 定时巡检，实现自动记录故障日志。
11. 编写 backup_mysql.sh 和 restore_mysql.sh，实现数据库备份与恢复。
12. 编写 start.sh、stop.sh、restart.sh、status.sh，实现基础一键运维管理。
13. 编写 troubleshooting_sop.md，整理常见故障排查流程。

---

## 十六、后续可优化方向

1. 接入 Prometheus + Grafana 做可视化监控。
2. 增加企业微信、钉钉或邮件告警。
3. 使用 Jenkins 实现自动构建和部署。
4. 将项目迁移到 Kubernetes。
5. 增加 Nginx HTTPS 配置。
6. 增加日志轮转，防止日志文件过大。
7. 优化数据库密码管理方式，避免明文写入脚本。
