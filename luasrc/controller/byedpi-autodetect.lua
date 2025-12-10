module("luci.controller.byedpi-autodetect", package.seeall)

function index()
    entry({"admin", "services", "byedpi", "autodetect"}, call("action_autodetect"), _("Auto-detect"), 10)
    entry({"admin", "services", "byedpi", "autodetect_status"}, call("action_autodetect_status"), nil).leaf = true
    entry({"admin", "services", "byedpi", "autodetect_log"}, call("action_autodetect_log"), nil).leaf = true
    entry({"admin", "services", "byedpi", "autodetect_stop"}, call("action_autodetect_stop"), nil).leaf = true
end

function action_autodetect()
    local sys = require "luci.sys"
    local http = require "luci.http"
    
    local action = http.formvalue("action")
    
    if action == "start" then
        -- Запускаем автоподбор в фоне
        sys.call("nohup /usr/sbin/byedpi-autodetect >/tmp/byedpi-autodetect.log 2>&1 &")
        http.write_json({success = true, message = "Auto-detection started"})
    else
        -- Показываем страницу автоподбора
        local template = require "luci.template"
        template.render("byedpi/autodetect")
    end
end

function action_autodetect_status()
    local sys = require "luci.sys"
    local uci = require "luci.model.uci".cursor()
    local http = require "luci.http"
    
    local status = {
        running = sys.call("pgrep -f 'byedpi-autodetect' >/dev/null") == 0,
        pid = sys.exec("pgrep -f 'byedpi-autodetect' 2>/dev/null"),
        config_mode = uci:get("byedpi", "settings", "mode") or "0",
        config_port = uci:get("byedpi", "settings", "port") or "443"
    }
    
    http.prepare_content("application/json")
    http.write_json(status)
end

function action_autodetect_log()
    local sys = require "luci.sys"
    local http = require "luci.http"
    
    local log = ""
    if nixio.fs.access("/tmp/byedpi-autodetect.log") then
        log = sys.exec("tail -n 100 /tmp/byedpi-autodetect.log 2>/dev/null")
    end
    
    http.prepare_content("text/plain")
    http.write(log)
end

function action_autodetect_stop()
    local sys = require "luci.sys"
    local http = require "luci.http"
    
    sys.call("pkill -f 'byedpi-autodetect' 2>/dev/null")
    http.write_json({success = true, message = "Auto-detection stopped"})
end
