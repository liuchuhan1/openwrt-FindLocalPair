local fs = require "nixio.fs"
local sys = require "luci.sys"

m = Map("owrt-peer", _("OWRT Peer 内网路由器发现"),
    _("两台OpenWRT路由器通过ICMP触发+UDP认证互相发现对方IP。支持大网段扫描和静态IP模式。"))

s = m:section(TypedSection, "owrt-peer", _("基本设置"))
s.addremove = false
s.anonymous = true

o = s:option(Flag, "enabled", _("启用服务"))
 o.rmempty = false
 o.default = 0

o = s:option(ListValue, "mode", _("工作模式"))
 o:value("scan", _("扫描模式 - 主动扫描内网发现对方"))
 o:value("manual", _("静态模式 - 使用已知IP，断联后才扫描"))
 o.default = "scan"
 o.rmempty = false

o = s:option(Value, "token", _("预共享密钥"))
 o.password = true
 o.datatype = "rangelength(8,16)"
 o.rmempty = false
 o.placeholder = "8-16位字符"
 o.description = _("双方必须设置相同的密钥，长度8-16位字符。用于UDP认证包的HMAC签名。")

o = s:option(Value, "peer_ip", _("对端IP地址"))
 o.datatype = "ipaddr"
 o.placeholder = "10.169.7.100"
 o:depends("mode", "manual")
 o.description = _("静态模式下，优先尝试连接此IP。断联后才扫描网段。")

o = s:option(Value, "scan_net", _("扫描网段"))
 o.datatype = "cidr"
 o.default = "10.0.0.0/17"
 o.placeholder = "10.0.0.0/17"
 o.description = _("CIDR格式，如 10.169.0.0/17。扫描模式必填，静态模式下作为断联后备。")

o = s:option(Value, "iface", _("监听接口"))
 o.default = "auto"
 o.placeholder = "auto"
 o.description = _("设为 auto 自动检测有10.x IP的接口。如需指定，如 wwan、br-lan。")

o = s:option(Value, "port", _("UDP端口"))
 o.datatype = "port"
 o.default = "9876"
 o.description = _("双方通信的UDP端口，必须相同。")

o = s:option(Value, "heartbeat", _("心跳间隔 (秒)"))
 o.datatype = "uinteger"
 o.default = "30"
 o.description = _("双方定时交换心跳包的时间间隔。")

o = s:option(Value, "fail_max", _("失败重试次数"))
 o.datatype = "uinteger"
 o.default = "3"
 o.description = _("连续心跳失败多少次后判定失联并重新发现。")

o = s:option(Value, "concurrent", _("扫描并发数"))
 o.datatype = "uinteger"
 o.default = "200"
 o.description = _("同时发送ping的最大数量。并发越高扫描越快，但占用资源越多。")

o = s:option(Value, "ping_wait", _("Ping超时 (秒)"))
 o.datatype = "uinteger"
 o.default = "1"
 o.description = _("单个ping的超时时间。扫描大网段时建议设为1秒。")

s2 = m:section(TypedSection, "owrt-peer", _("运行状态"))
s2.addremove = false
s2.anonymous = true
s2.template = "cbi/nullsection"

o = s2:option(DummyValue, "_status", _("当前状态"))
function o.cfgvalue(self, section)
    local state = fs.readfile("/tmp/owrt_peer_state") or "unknown"
    state = state:gsub("%s+", "")
    local peer_ip = fs.readfile("/tmp/owrt_peer_ip") or ""
    peer_ip = peer_ip:gsub("%s+", "")
    local lastseen = fs.readfile("/tmp/owrt_peer_lastseen") or "0"
    lastseen = tonumber(lastseen:gsub("%s+", "")) or 0
    local now = os.time()
    local diff = now - lastseen

    local status_text = ""
    if state == "connected" and peer_ip ~= "" then
        if diff < 60 then
            status_text = string.format("<span style='color:green'>已连接</span> - 对方IP: %s (%.0f秒前)", peer_ip, diff)
        elseif diff < 300 then
            status_text = string.format("<span style='color:orange'>延迟</span> - 对方IP: %s (%.0f秒前)", peer_ip, diff)
        else
            status_text = string.format("<span style='color:red'>失联</span> - 对方IP: %s (%.0f秒前)", peer_ip, diff)
        end
    elseif state == "discovering" then
        status_text = "<span style='color:blue'>发现中...</span>"
    elseif state == "lost" then
        status_text = "<span style='color:red'>已断联</span>"
    else
        status_text = "<span style='color:gray'>未启动或未知</span>"
    end

    return status_text
end

o = s2:option(DummyValue, "_myip", _("本机IP"))
function o.cfgvalue(self, section)
    local iface = m:get(section, "iface") or "auto"
    if iface == "auto" then
        local f = io.popen("ip -o addr show | grep 'inet 10\.' | head -n1 | awk '{print $2, $4}'")
        if f then
            local result = f:read("*l") or ""
            f:close()
            if result ~= "" then
                local parts = {}
                for part in result:gmatch("%S+") do table.insert(parts, part) end
                if #parts >= 2 then
                    return string.format("接口: %s, IP: %s", parts[1], parts[2])
                end
            end
        end
        return "自动检测中..."
    else
        local f = io.popen("ip addr show " .. iface .. " 2>/dev/null | grep 'inet ' | head -n1 | awk '{print $2}'")
        if f then
            local ip = f:read("*l") or ""
            f:close()
            if ip ~= "" then
                return string.format("接口: %s, IP: %s", iface, ip)
            end
        end
        return "无法获取IP"
    end
end

return m
