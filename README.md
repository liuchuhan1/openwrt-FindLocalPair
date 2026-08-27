# OpenWRT 内网路由器IP发现服务 (owrt-peer v5)

## 核心特性
- **对等模式**: `manual` / `scan` 两种模式，无主次之分
- **双方同时监听**: ICMP + UDP 双监听
- **大网段扫描**: /17 等任意 CIDR，并发 200 ping
- **自动接口检测**: `auto` 自动找 10.x 接口
- **PSK认证**: HMAC-SHA256 + 时间戳防重放
- **LuCI界面**: 完整的Web配置界面
- **密钥限制**: 预共享密钥 8-16 位字符

## 模式说明

| 模式 | 行为 |
|------|------|
| `scan` | 启动即扫描内网，主动发现对方 |
| `manual` | 优先连接配置的 `peer_ip`，断联后才扫描 |

## 四种组合行为

| A | B | 行为 |
|---|---|------|
| manual | manual | 直接互相心跳，断联后先重试静态IP再扫描 |
| manual | scan | scan方扫描 → ping到manual → manual回复UDP → 建立连接 |
| scan | manual | 同上，对称 |
| scan | scan | 双方都扫描，互相发现后建立连接 |

## 安装方式

### 方式一：手动安装（任意OpenWRT）

```bash
# 1. 安装依赖
opkg update
opkg install tcpdump netcat luci-base

# 2. 上传文件（保持目录结构）
#   etc/config/owrt-peer
#   etc/init.d/owrt-peer
#   etc/uci-defaults/99-owrt-peer
#   usr/bin/owrt-peer-discover
#   usr/bin/owrt-peer-status
#   usr/lib/lua/luci/controller/owrt-peer.lua
#   usr/lib/lua/luci/model/cbi/owrt-peer/owrt-peer.lua

# 3. 设置权限
chmod +x /etc/init.d/owrt-peer
chmod +x /usr/bin/owrt-peer-discover
chmod +x /usr/bin/owrt-peer-status
chmod +x /etc/uci-defaults/99-owrt-peer

# 4. 初始化配置
/etc/uci-defaults/99-owrt-peer

# 5. 重启LuCI
rm -rf /tmp/luci-indexcache /tmp/luci-modulecache
/etc/init.d/uhttpd restart
```

### 方式二：编译为ipk（推荐）

将本目录放入 OpenWRT SDK/package/ 下编译。

## LuCI 配置

访问 `http://路由器IP/cgi-bin/luci/admin/services/owrt-peer`

界面包含：启用开关、模式选择、预共享密钥(密码框)、对端IP、扫描网段、监听接口、UDP端口、心跳间隔、失败重试、扫描并发、Ping超时，以及实时运行状态显示。

## 命令行配置示例

```bash
# 路由器A (scan模式)
uci set owrt-peer.main.enabled='1'
uci set owrt-peer.main.mode='scan'
uci set owrt-peer.main.token='MySecret12'
uci set owrt-peer.main.scan_net='10.169.0.0/17'
uci set owrt-peer.main.iface='auto'
uci commit owrt-peer
/etc/init.d/owrt-peer enable
/etc/init.d/owrt-peer start

# 路由器B (manual模式)
uci set owrt-peer.main.enabled='1'
uci set owrt-peer.main.mode='manual'
uci set owrt-peer.main.token='MySecret12'
uci set owrt-peer.main.peer_ip='10.169.7.100'
uci set owrt-peer.main.scan_net='10.169.0.0/17'
uci set owrt-peer.main.iface='auto'
uci commit owrt-peer
/etc/init.d/owrt-peer enable
/etc/init.d/owrt-peer start
```

## 查询对方IP

```bash
owrt-peer-status
cat /tmp/owrt_peer_ip
```

## 日志

```bash
tail -f /tmp/owrt-peer.log
logread -f -e owrt-peer
```

## 防火墙

```bash
iptables -I INPUT -p icmp --icmp-type echo-request -j ACCEPT
iptables -I INPUT -p icmp --icmp-type echo-reply -j ACCEPT
iptables -I INPUT -p udp --dport 9876 -j ACCEPT
```

## 参数说明

| 参数 | 说明 | 默认值 | 范围 |
|------|------|--------|------|
| enabled | 启用服务 | 0 | 0/1 |
| mode | 工作模式 | scan | scan/manual |
| token | 预共享密钥 | (空) | 8-16位字符 |
| peer_ip | 静态对端IP | (空) | IP地址 |
| scan_net | 扫描网段 | 10.0.0.0/17 | CIDR |
| iface | 监听接口 | auto | 接口名或auto |
| port | UDP端口 | 9876 | 1-65535 |
| heartbeat | 心跳间隔 | 30 | 秒 |
| fail_max | 失败重试 | 3 | 次数 |
| concurrent | 扫描并发 | 200 | 数量 |
| ping_wait | Ping超时 | 1 | 秒 |
