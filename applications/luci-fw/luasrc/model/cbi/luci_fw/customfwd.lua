--[[
LuCI - Lua Configuration Interface

Copyright 2008 Steven Barth <steven@midlink.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id$
]]--
require("luci.sys")
m = Map("firewall", translate("fw_portfw"), translate("fw_portfw1"))


s = m:section(TypedSection, "redirect", "")
s.addremove = true
s.anonymous = true

name = s:option(Value, "_name", translate("name"))
name.rmempty = true
name.size = 10

iface = s:option(ListValue, "src", translate("fw_zone"))
iface.default = "wan"
luci.model.uci.foreach("firewall", "zone",
	function (section)
		iface:value(section.name)
	end)
	
s:option(Value, "src_ip").optional = true
s:option(Value, "src_mac").optional = true

sport = s:option(Value, "src_port")
sport.optional = true
sport:depends("proto", "tcp")
sport:depends("proto", "udp")

proto = s:option(ListValue, "proto", translate("protocol"))
proto.optional = true
proto:value("")
proto:value("tcp", "TCP")
proto:value("udp", "UDP")

dport = s:option(Value, "src_dport")
dport.size = 5
dport.optional = true
dport:depends("proto", "tcp")
dport:depends("proto", "udp")

to = s:option(Value, "dest_ip")
for i, dataset in ipairs(luci.sys.net.arptable()) do
	to:value(dataset["IP address"])
end

toport = s:option(Value, "dest_port")
toport.optional = true
toport.size = 5

return m