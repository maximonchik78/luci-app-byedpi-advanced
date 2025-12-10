module("luci.controller.byedpi", package.seeall)

function index()
    if not nixio.fs.access("/etc/config/byedpi") then
        return
    end

    entry({"admin", "services", "byedpi"}, cbi("byedpi"), _("ByeDPI"), 60)
    entry({"admin", "services", "byedpi", "status"}, call("action_status")).leaf = true
    entry({"admin", "services", "byedpi", "autodetect"}, call("action_autodetect")).leaf = true
    entry({"admin", "services", "byedpi", "start"}, call("action_start")).leaf = true
    entry({"admin", "services", "byedpi", "stop"}, call("action_stop")).leaf = true
    entry({"admin", "services", "byedpi", "test"}, call("action_test")).leaf = true
    entry({"admin", "services", "byedpi", "log"}, call("action_log")).leaf = true
end

function action_status()
    local sys = require "luci.sys"
    local uci = require "luci.model.uci".cursor()
    
    local status = {
        running = sys.call("pgrep -f '/usr/sbin/byedpi' >/dev/null") == 0,
        enabled = uci:get("byedpi", "settings", "enabled") or "0",
        mode = uci:get("byedpi", "settings", "mode") or "0",
        port = uci:get("byedpi", "settings", "port") or "443",
        autodetect = uci:get("byedpi", "settings", "autodetect") or "0"
    }
    
    if nixio.fs.access("/tmp/byedpi-autodetect.log") then
        status.log = sys.exec("tail -n 10 /tmp/byedpi-autodetect.log 2>/dev/null") or ""
    end
    
    luci.http.prepare_content("application/json")
    luci.http.write_json(status)
end

function action_autodetect()
    local sys = require "luci.sys"
    sys.call("nohup /usr/sbin/byedpi-autodetect >/tmp/byedpi-detection.log 2>&1 &")
    
    luci.http.prepare_content("application/json")
    luci.http.write_json({success = true, message = "Auto-detection started"})
end

function action_start()
    local sys = require "luci.sys"
    sys.call("/etc/init.d/byedpi start >/dev/null 2>&1")
    luci.http.redirect(luci.dispatcher.build_url("admin/services/byedpi"))
end

function action_stop()
    local sys = require "luci.sys"
    sys.call("/etc/init.d/byedpi stop >/dev/null 2>&1")
    luci.http.redirect(luci.dispatcher.build_url("admin/services/byedpi"))
end

function action_test()
    local sys = require "luci.sys"
    local result = sys.exec("/etc/init.d/byedpi test 2>&1")
    
    luci.http.prepare_content("text/plain")
    luci.http.write(result)
end

function action_log()
    local sys = require "luci.sys"
    local log = ""
    
    if nixio.fs.access("/tmp/byedpi-autodetect.log") then
        log = log .. "=== Auto-detection Log ===\n" .. 
              sys.exec("tail -n 50 /tmp/byedpi-autodetect.log 2>/dev/null") .. "\n\n"
    end
    
    if nixio.fs.access("/var/log/byedpi.log") then
        log = log .. "=== Service Log ===\n" .. 
              sys.exec("tail -n 50 /var/log/byedpi.log 2>/dev/null")
    end
    
    luci.http.prepare_content("text/plain")
    luci.http.write(log)
end
