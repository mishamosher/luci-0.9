--[[
LuCI - Lua Configuration Interface

Copyright 2008 Steven Barth <steven@midlink.org>
Copyright 2008 Jo-Philipp Wich <xm@leipzig.freifunk.net>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id$
]]--
module("luci.controller.mini.uci", package.seeall)

function index()
	local i18n = luci.i18n.translate
	
	entry({"mini", "uci"}, nil, i18n("config"))
	entry({"mini", "uci", "changes"}, call("action_changes"), i18n("changes"))
	entry({"mini", "uci", "revert"}, call("action_revert"), i18n("revert"))
	entry({"mini", "uci", "apply"}, call("action_apply"), i18n("apply"))
end

function convert_changes(changes)
	local ret = {}
	for r, tbl in pairs(changes) do
		for s, os in pairs(tbl) do
			for o, v in pairs(os) do
				local val, str
				if (v == "") then
					str = "-"
					val = ""
				else
					str = ""
					val = "="..v
				end
				str = r.."."..s
				if o ~= ".type" then
					str = str.."."..o
				end
				table.insert(ret, str..val)
			end
		end
	end
	return table.concat(ret, "\n")
end

function action_changes()
	local changes = convert_changes(luci.model.uci.changes())
	luci.template.render("mini/uci_changes", {changes=changes})
end

function action_apply()
	local changes = luci.model.uci.changes()
	local output  = ""
	
	if changes then
		local com = {}
		local run = {}
		
		-- Collect files to be applied and commit changes
		for r, tbl in pairs(changes) do
			if r then
				luci.model.uci.load(r)
				luci.model.uci.commit(r)
				luci.model.uci.unload(r)
				if luci.config.uci_oncommit and luci.config.uci_oncommit[r] then
					run[luci.config.uci_oncommit[r]] = true
				end
			end
		end
		
		-- Search for post-commit commands
		for cmd, i in pairs(run) do
			output = output .. cmd .. ":" .. luci.sys.exec(cmd) .. "\n"
		end
	end
	
	
	luci.template.render("mini/uci_apply", {changes=convert_changes(changes), output=output})
end


function action_revert()
	local changes = luci.model.uci.changes()
	if changes then
		local revert = {}
		
		-- Collect files to be reverted
		for r, tbl in pairs(changes) do
			luci.model.uci.load(r)
			luci.model.uci.revert(r)
			luci.model.uci.unload(r)
		end
	end
	
	luci.template.render("mini/uci_revert", {changes=convert_changes(changes)})
end