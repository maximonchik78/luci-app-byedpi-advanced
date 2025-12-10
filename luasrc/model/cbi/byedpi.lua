m = Map("byedpi", translate("ByeDPI - Advanced DPI Bypass"), 
    translate("Tool for bypassing Deep Packet Inspection with auto-detection"))

s = m:section(TypedSection, "settings", translate("Main Settings"))
s.anonymous = true

enabled = s:option(Flag, "enabled", translate("Enable Service"))
enabled.rmempty = false

mode = s:option(ListValue, "mode", translate("Bypass Mode"))
mode:value("0", translate("Auto (recommended)"))
mode:value("1", translate("1 - TTL manipulation"))
mode:value("2", translate("2 - Wrong TCP Checksums"))
mode:value("3", translate("3 - Wrong TCP Sequence"))
mode:value("4", translate("4 - TCP Fragmentation"))
mode:value("5", translate("5 - TCP ACK Tampering"))
mode:value("6", translate("6 - TCP Checksum Tampering"))
mode.default = "0"

port = s:option(Value, "port", translate("Ports"))
port.placeholder = "443,80"
port.default = "443"
port.datatype = "portrange"

ipv6 = s:option(Flag, "ipv6", translate("Enable IPv6"))
ipv6.optional = true

autodetect = s:option(Flag, "autodetect", translate("Auto-detect DPI"))
autodetect.description = translate("Automatically detect and configure optimal bypass method")

interval = s:option(Value, "autodetect_interval", translate("Auto-detect Interval (seconds)"))
interval.placeholder = "3600"
interval.default = "3600"
interval.datatype = "uinteger"
interval:depends("autodetect", "1")

test_urls = s:option(Value, "test_urls", translate("Test URLs"))
test_urls.placeholder = "https://rutracker.org https://vk.com"
test_urls.default = "https://rutracker.org https://vk.com https://telegram.org"
test_urls:depends("autodetect", "1")

log_level = s:option(ListValue, "log_level", translate("Log Level"))
log_level:value("0", translate("Disabled"))
log_level:value("1", translate("Errors only"))
log_level:value("2", translate("Info"))
log_level:value("3", translate("Debug"))
log_level.default = "1"

interface = s:option(Value, "interface", translate("Network Interface"))
interface.placeholder = "br-lan"
interface.default = "br-lan"

btn = s:option(Button, "_autodetect", translate("Run Detection Now"))
btn.inputtitle = translate("Start Auto-detection")
btn.inputstyle = "apply"
function btn.write()
    luci.sys.call("/usr/sbin/byedpi-autodetect >/tmp/byedpi-detection.log 2>&1 &")
    luci.http.redirect(luci.dispatcher.build_url("admin/services/byedpi"))
end

-- Schedule Section
sched = m:section(TypedSection, "schedule", translate("Schedule"))
sched.anonymous = true

sched_enabled = sched:option(Flag, "enabled", translate("Enable Schedule"))

start_time = sched:option(Value, "start_time", translate("Start Time"))
start_time.placeholder = "00:00"
start_time:depends("enabled", "1")

end_time = sched:option(Value, "end_time", translate("End Time"))
end_time.placeholder = "06:00"
end_time:depends("enabled", "1")

days = sched:option(Value, "days", translate("Days"))
days.placeholder = "mon,tue,wed,thu,fri,sat,sun"
days.default = "mon,tue,wed,thu,fri,sat,sun"
days:depends("enabled", "1")

-- Statistics Section
stats = m:section(TypedSection, "statistics", translate("Statistics"))
stats.anonymous = true

stats_enabled = stats:option(Flag, "enabled", translate("Enable Statistics"))

save_interval = stats:option(Value, "save_interval", translate("Save Interval (seconds)"))
save_interval.placeholder = "300"
save_interval.default = "300"
save_interval.datatype = "uinteger"
save_interval:depends("enabled", "1")

return m
