module("luci.controller.owrt-peer", package.seeall)

function index()
    if not nixio.fs.access("/etc/config/owrt-peer") then
        return
    end

    local page = entry({"admin", "services", "owrt-peer"}, cbi("owrt-peer/owrt-peer"), _("OWRT Peer"), 60)
    page.dependent = true
    page.acl_depends = { "luci-app-owrt-peer" }
end
