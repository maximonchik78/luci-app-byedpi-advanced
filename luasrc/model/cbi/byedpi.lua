m = Map("byedpi", translate("ByeDPI - Advanced DPI Bypass"), 
    translate("Tool for bypassing Deep Packet Inspection with auto-detection"))

s = m:section(TypedSection, "settings", translate("Main Settings"))
s.anonymous = true

-- Основные настройки
enabled = s:option(Flag, "enabled", translate("Enable Service"))
enabled.rmempty = false

mode = s:option(ListValue, "mode", translate("Bypass Mode"))
mode:value("0", translate("Auto (recommended)"))
mode:value("1", translate("1 - Fragment TCP"))
mode:value("2", translate("2 - Wrong Checksum"))
mode:value("3", translate("3 - Wrong Sequence"))
mode:value("4", translate("4 - Tamper TCP ACK"))
mode:value("5", translate("5 - Tamper TCP Checksum"))
mode.default = "0"

port = s:option(DynamicList, "port", translate("Ports"))
port.placeholder = "443,80"
port.default = "443"
port.datatype = "portrange"

s:option(Flag, "ipv6", translate("Enable IPv6")).optional = true

-- Автоподбор
autodetect = s:option(Flag, "autodetect", translate("Auto-detect DPI"))
autodetect.description = translate("Automatically detect and configure optimal bypass method")

interval = s:option(Value, "autodetect_interval", translate("Auto-detect Interval"))
interval.placeholder = "3600"
interval.default = "3600"
interval.datatype = "uinteger"
interval:depends("autodetect", "1")

test_urls = s:option(DynamicList, "test_urls", translate("Test URLs"))
test_urls.placeholder = "https://example.com"
test_urls.default = "https://rutracker.org"
test_urls:depends("autodetect", "1")

-- Интерфейс
interface = s:option(ListValue, "interface", translate("Network Interface"))
interface:value("", translate("All interfaces"))
for _, iface in ipairs(luci.sys.net.devices()) do
    if iface ~= "lo" then
        interface:value(iface)
    end
end

-- Кнопка ручного запуска автоподбора
btn = s:option(Button, "_autodetect", translate("Run Detection Now"))
btn.inputtitle = translate("Start Auto-detection")
btn.inputstyle = "apply"
function btn.write()
    luci.sys.call("/etc/init.d/byedpi autodetect >/tmp/byedpi-detection.log 2>&1 &")
    luci.http.redirect(luci.dispatcher.build_url("admin/services/byedpi/status"))
end

-- Расширенные настройки
advanced = m:section(TypedSection, "settings", translate("Advanced Settings"))
advanced.anonymous = true

log_level = advanced:option(ListValue, "log_level", translate("Log Level"))
log_level:value("0", translate("Disabled"))
log_level:value("1", translate("Errors only"))
log_level:value("2", translate("Info"))
log_level:value("3", translate("Debug"))

-- Расписание
sched = m:section(TypedSection, "schedule", translate("Schedule"))
sched.anonymous = true

sched:option(Flag, "enabled", translate("Enable Schedule"))
start = sched:option(Value, "start_time", translate("Start Time"))
start.placeholder = "HH:MM"
end_time = sched:option(Value, "end_time", translate("End Time"))
end_time.placeholder = "HH:MM"
days = sched:option(Value, "days", translate("Days"))
days.placeholder = "mon,tue,wed,thu,fri,sat,sun"

return m
