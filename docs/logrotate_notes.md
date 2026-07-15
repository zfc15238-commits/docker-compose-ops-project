# logrotate 日志轮转说明

## 1. 配置目的

项目中的巡检脚本和 cron 定时任务会持续写入日志：

- logs/check.log
- logs/cron.log

如果长期运行，日志文件会不断变大，占用磁盘空间。因此使用 logrotate 对日志进行轮转管理。

## 2. 配置文件

项目内保存配置文件：

docs/logrotate-compose-study.conf

实际生效位置：

/etc/logrotate.d/compose-study

## 3. 轮转策略

daily：每天轮转一次  
rotate 7：保留 7 份历史日志  
missingok：日志不存在不报错  
notifempty：空日志不轮转  
compress：压缩旧日志  
delaycompress：延迟压缩  
copytruncate：复制日志后清空原日志文件，保证脚本继续写入原文件  
su zfc zfc：指定使用 zfc 用户和用户组执行轮转，解决用户目录权限检查问题  

## 4. 测试命令

sudo logrotate -d /etc/logrotate.d/compose-study  
sudo logrotate -f /etc/logrotate.d/compose-study  
ls -lh logs  
./scripts/check.sh  
tail -20 logs/check.log  

## 5. 项目意义

通过配置 logrotate，可以避免巡检日志和定时任务日志长期增长，提升项目的可维护性，更接近真实运维场景。
