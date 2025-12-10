module("luci.controller.byedpi", package.seeall)

function index()
    entry({"admin", "services", "byedpi"}, cbi("byedpi"), _("ByeDPI"), 60)
    entry({"admin", "services", "byedpi", "status"}, call("action_status"))
    entry({"admin", "services", "byedpi", "autodetect"}, call("action_autodetect"))
    entry({"admin", "services", "byedpi", "start"}, call("action_start"))
    entry({"admin", "services", "byedpi", "stop"}, call("action_stop"))
    entry({"admin", "services", "byedpi", "test"}, call("action_test"))
    entry({"admin", "services", "byedpi", "log"}, call("action_log"))
end

function action_status()
    local sys = require "luci.sys"
    local uci = require "luci.model.uci".cursor()
    
    local status = {
        running = sys.call("pgrep -f '/usr/sbin/byedpi' >/dev/null") == 0,
        enabled = uci:get("byedpi", "settings", "enabled") or "0",
        mode = uci:get("byedpi", "settings", "mode") or "0",
        port = uci:get("byedpi", "settings", "port") or "443"
    }
    
    -- Читаем последние результаты автоподбора
    if nixio.fs.access("/tmp/byedpi-detection.log") then
        status.log = sys.exec("tail -n 20 /tmp/byedpi-detection.log")
    end
    
    luci.http.prepare_content("application/json")
    luci.http.write_json(status)
end

function action_autodetect()
    local sys = require "luci.sys"
    
    -- Запускаем автоподбор в фоне
    sys.call("nohup /usr/sbin/byedpi-autodetect >/tmp/byedpi-detection.log 2>&1 &")
    
    luci.http.prepare_content("application/json")
    luci.http.write_json({success = true, message = "Auto-detection started"})
end

function action_test()
    local sys = require "luci.sys"
    local result = sys.exec("/etc/init.d/byedpi test")
    
    luci.http.prepare_content("text/plain")
    luci.http.write(result)
end

function action_log()
    local sys = require "luci.sys"
    local log = ""
    
    if nixio.fs.access("/tmp/byedpi-autodetect.log") then
        log = log .. "=== Auto-detection Log ===\n" .. 
              sys.exec("tail -n 50 /tmp/byedpi-autodetect.log") .. "\n\n"
    end
    
    if nixio.fs.access("/var/log/byedpi.log") then
        log = log .. "=== Service Log ===\n" .. 
              sys.exec("tail -n 50 /var/log/byedpi.log")
    end
    
    luci.http.prepare_content("text/plain")
    luci.http.write(log)
end

function action_start()
    sys.call("/etc/init.d/byedpi start >/dev/null 2>&1")
    luci.http.redirect(luci.dispatcher.build_url("admin/services/byedpi"))
end

function action_stop()
    sys.call("/etc/init.d/byedpi stop >/dev/null 2>&1")
    luci.http.redirect(luci.dispatcher.build_url("admin/services/byedpi"))
end
