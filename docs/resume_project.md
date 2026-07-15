# Docker Compose 三容器运维项目简历整理

## 一、项目名称

基于 Docker Compose 的 Nginx + Flask + MySQL 容器化部署与运维管理项目


---

## 二、项目简介

本项目基于 Docker Compose 搭建 Nginx、Python Flask App、MySQL 三容器服务，实现了从前端请求入口、后端接口服务到数据库查询的完整访问链路。

项目通过 Nginx 反向代理将 `/api` 请求转发到 Flask 后端服务，Flask App 使用 PyMySQL 连接 MySQL 数据库并返回查询结果。

在基础部署完成后，进一步实现了容器健康检查、异常自动重启、故障演练、日志排查、巡检脚本、cron 定时巡检、MySQL 数据备份与恢复、一键启动停止脚本和故障排查 SOP 文档。


---

## 三、技术栈

Linux、Docker、Docker Compose、Nginx、Python Flask、MySQL、PyMySQL、Shell Script、Cron


---

## 四、项目架构

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

容器说明：

   nginx-compose        Nginx 反向代理入口
   python-app-compose   Python Flask 后端服务
   mysql-compose        MySQL 数据库服务


---

## 五、简历可写版本

### 版本一：简洁版

基于 Docker Compose 搭建 Nginx + Flask + MySQL 三容器项目，实现 Nginx 反向代理、Flask 后端接口、MySQL 数据持久化和容器间服务名通信；配置 healthcheck 与 restart 策略，完成服务故障演练、日志排查、巡检脚本、cron 定时巡检以及 MySQL 备份恢复脚本，提升项目的可维护性和基础运维能力。


---

### 版本二：详细版

使用 Docker Compose 编排 Nginx、Python Flask App、MySQL 三个容器服务，构建完整的 Nginx → App → MySQL 访问链路。通过 Nginx 将 `/api` 请求反向代理至 Flask 后端，后端使用 PyMySQL 连接 MySQL 并返回数据库查询结果。项目中配置了 MySQL 数据持久化、App healthcheck 健康检查和 restart: always 自动重启策略，并完成 App 停止、MySQL 停止、Nginx 代理端口错误、healthcheck 配置错误、网络断开等故障演练。编写 Shell 巡检脚本，实现容器状态、接口连通性、服务间网络和数据库连接检查，并结合 cron 实现定时巡检和日志记录。同时编写数据库备份与恢复脚本、一键启动/停止/重启/状态查看脚本，并整理故障排查 SOP 和 README 文档。


---

## 六、简历项目职责

1. 使用 Docker Compose 编排 Nginx、Flask App、MySQL 多容器服务。
2. 编写 Dockerfile 构建 Python Flask 后端镜像。
3. 配置 Nginx 反向代理，将 `/api` 请求转发至 Flask App。
4. 使用 Docker 自定义网络实现容器间通过服务名通信。
5. 配置 MySQL volume 挂载，实现数据库数据持久化。
6. 配置 healthcheck，实现 App 服务健康状态检测。
7. 配置 restart: always，提高容器异常退出后的自动恢复能力。
8. 通过 logs、ps、inspect、curl、exec 等命令完成故障定位。
9. 编写 check.sh 巡检脚本，实现容器、接口和网络连通性检查。
10. 使用 cron 定时执行巡检脚本，并将结果写入日志。
11. 编写 backup_mysql.sh 和 restore_mysql.sh，实现数据库备份与恢复。
12. 编写 start.sh、stop.sh、restart.sh、status.sh，实现基础一键运维管理。
13. 整理 troubleshooting_sop.md 和 README.md，完善项目文档。


---

## 七、项目亮点

1. 完成 Nginx + Flask + MySQL 三容器服务的完整部署。
2. 通过 Docker Compose 实现多服务统一编排和管理。
3. 使用 Docker 自定义网络实现容器间服务名通信。
4. 使用 volume 实现 MySQL 数据持久化。
5. 配置 healthcheck 和 restart: always，提高服务稳定性。
6. 完成多种故障演练，具备基础故障排查能力。
7. 编写巡检脚本，实现一键检查项目运行状态。
8. 配置 cron 定时巡检，实现自动记录故障日志。
9. 编写数据库备份和恢复脚本，提高数据安全性。
10. 编写一键运维脚本，提升项目管理效率。
11. 整理故障排查 SOP，形成标准化排查流程。


---

## 八、项目中遇到的问题与解决方案

### 1. /users 接口返回 500

问题现象：

   curl http://localhost:5000/users

返回 500。

排查方式：

   sudo docker compose logs app

原因：

   PyMySQL 连接 MySQL 8 时，缺少 cryptography 依赖。

解决方法：

   在 requirements.txt 中增加 cryptography，然后重新构建 App 镜像。

命令：

   sudo docker compose up -d --build app


---

### 2. Nginx 代理返回 502

问题现象：

   curl -i http://localhost:8082/api/users

返回 502 Bad Gateway。

排查方式：

   sudo docker compose logs nginx
   grep -R "proxy_pass" -n .

原因：

   Nginx proxy_pass 端口写错，例如写成 app:5999。

解决方法：

   改回 proxy_pass http://app:5000/;
   然后重启 Nginx。

命令：

   sudo docker compose restart nginx


---

### 3. MySQL 停止导致接口返回 500

问题现象：

   mysql-compose Exited
   /users 返回 500
   /api/users 返回 500

排查方式：

   sudo docker compose ps -a
   sudo docker compose logs app
   ./scripts/check.sh

原因：

   App 查询数据库时无法连接 MySQL。

解决方法：

   sudo docker compose start mysql
   ./scripts/check.sh


---

### 4. App 显示 unhealthy

问题现象：

   python-app-compose   Up (unhealthy)

排查方式：

   sudo docker inspect python-app-compose | grep -A 30 Health

原因：

   healthcheck 路径配置错误，例如把 /health 写成 /wrong。

解决方法：

   修改 docker-compose.yml 中的 healthcheck 路径，重新创建 App 容器。


---

### 5. cron 定时巡检报 sudo 密码错误

问题现象：

   sudo: a terminal is required to read the password
   sudo: a password is required

原因：

   普通用户 crontab 后台执行脚本时无法输入 sudo 密码。

解决方法：

   使用 sudo crontab -e，将定时任务放到 root crontab 中执行。


---

## 九、面试怎么介绍这个项目

可以这样说：

我做了一个基于 Docker Compose 的三容器部署项目，项目包含 Nginx、Python Flask App 和 MySQL 三个服务。Nginx 作为入口，将 `/api` 请求反向代理到 Flask 后端，Flask 后端通过 PyMySQL 连接 MySQL 数据库并返回查询结果。

在基础部署完成后，我继续对项目做了运维增强，比如配置 MySQL 数据持久化、App 健康检查、容器自动重启策略，并模拟了 App 停止、MySQL 停止、Nginx 代理配置错误和 healthcheck 错误等故障。通过 docker compose ps、logs、inspect、curl、exec 等命令定位问题。

后续我还编写了 Shell 巡检脚本，用来检查容器状态、接口访问、Nginx 到 App 网络、App 到 MySQL 网络，并结合 cron 实现定时巡检和日志记录。同时编写了 MySQL 备份恢复脚本和一键启动、停止、重启、状态查看脚本，最后整理了 README 和故障排查 SOP 文档。


---

## 十、面试常见问题与回答

### 1. 你这个项目的访问链路是什么？

回答：

用户访问 localhost:8082/api/users，请求先进入 Nginx 容器，Nginx 根据 `/api/` 路径将请求转发到 Flask App 容器的 5000 端口，Flask App 查询 MySQL 容器中的 compose_users 表，最后返回 JSON 数据。


---

### 2. 为什么 Flask 连接 MySQL 时 host 写 mysql，而不是 localhost？

回答：

因为 Flask App 和 MySQL 分别运行在不同容器中。localhost 在 App 容器里只代表 App 容器自己，不代表 MySQL 容器。Docker Compose 中同一个网络下的服务可以通过服务名通信，所以 App 连接 MySQL 时使用服务名 mysql。


---

### 3. 502 和 500 有什么区别？

回答：

502 一般说明 Nginx 收到了请求，但是连接后端 App 失败，问题多在 Nginx 到 App 这一层，比如 App 容器停止、proxy_pass 配置错误、端口错误或者网络异常。

500 一般说明请求已经到达 App，但是 App 内部处理失败，常见原因是 App 连接 MySQL 失败、Python 代码报错、依赖缺失或者 SQL 执行异常。


---

### 4. healthcheck 有什么作用？

回答：

healthcheck 用来判断容器内部服务是否真正可用。普通的 Up 只能说明容器进程还在运行，而 healthy 表示健康检查接口也能正常访问。比如本项目中 App 的 healthcheck 检查的是 http://localhost:5000/health。


---

### 5. restart: always 有什么作用？

回答：

restart: always 用于在容器异常退出后让 Docker 自动尝试重启容器。我在项目中通过杀掉 App 容器主进程进行验证，发现 RestartCount 从 0 变成 1，说明自动重启策略生效。


---

### 6. 你怎么判断 MySQL 停了？

回答：

首先通过 docker compose ps -a 查看 mysql-compose 是否为 Exited。然后通过 check.sh 巡检可以看到 App 接口和 Nginx 代理接口返回 500，但 Nginx -> App 网络正常，App -> MySQL 网络异常。结合 App 日志中的 PyMySQL 报错，可以判断问题在数据库层。


---

### 7. 你写的 check.sh 主要检查什么？

回答：

check.sh 主要检查六项内容：容器状态、App 重启次数、App 直连接口、Nginx 代理接口、Nginx 容器访问 App、App 容器访问 MySQL 端口。最后根据检查结果输出巡检通过或失败，并写入日志。


---

### 8. 你为什么要做 cron 定时巡检？

回答：

手动执行巡检脚本只能在人工操作时发现问题，cron 可以定时自动执行巡检脚本，把结果写入日志。这样即使不手动执行，也能通过日志看到服务什么时候正常、什么时候异常。


---

### 9. 你怎么做数据库备份和恢复？

回答：

我使用 mysqldump 对 compose_test 数据库进行备份，并封装成 backup_mysql.sh 脚本，自动生成带时间戳的 SQL 备份文件。恢复时使用 restore_mysql.sh 指定备份文件导入数据库，恢复后通过数据库查询、Flask 直连接口和 Nginx 代理接口验证数据是否恢复成功。


---

### 10. 这个项目还能怎么优化？

回答：

后续可以继续接入 Prometheus 和 Grafana 做可视化监控，增加钉钉或邮件告警，配置日志轮转，使用 Jenkins 做自动构建部署，或者迁移到 Kubernetes 进行更完整的容器编排管理。


---

## 十一、简历最终推荐写法

项目名称：

   基于 Docker Compose 的 Nginx + Flask + MySQL 容器化部署与运维管理项目

项目描述：

   使用 Docker Compose 编排 Nginx、Python Flask App、MySQL 三个容器服务，构建完整的 Nginx → App → MySQL 访问链路。通过 Nginx 实现 `/api` 请求反向代理，Flask App 使用 PyMySQL 查询 MySQL 数据并返回结果。项目配置 MySQL 数据持久化、App healthcheck 健康检查和 restart: always 自动重启策略，并完成 App、MySQL、Nginx、网络等故障演练。编写 Shell 巡检脚本和 cron 定时任务，实现服务状态自动检查和日志记录；编写 MySQL 备份恢复脚本及一键启动、停止、重启、状态查看脚本，提升项目可维护性和基础运维能力。

技术栈：

   Linux、Docker、Docker Compose、Nginx、Python Flask、MySQL、PyMySQL、Shell、Cron

项目职责：

   1. 使用 Docker Compose 编排 Nginx、Flask App、MySQL 三容器服务。
   2. 编写 Dockerfile 构建 Flask 后端镜像，并配置 Nginx 反向代理。
   3. 配置 Docker 网络和 volume，实现容器间通信和 MySQL 数据持久化。
   4. 配置 healthcheck 和 restart 策略，提高服务稳定性。
   5. 完成 502、500、unhealthy、数据库停止等故障演练与日志排查。
   6. 编写 check.sh、backup_mysql.sh、restore_mysql.sh 及一键运维脚本。
   7. 使用 cron 实现定时巡检，并整理 README 和故障排查 SOP 文档。
