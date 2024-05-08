-- Followt these steps to profile for nvim plugin: 
-- 1. Install plugin: "stevearc/profile.nvim". You can uncomment [Profile] codes in plugin_manager.lua.
-- 2. Open nvim with "profile" argument. "nvim.exe sal_profile", etc.
-- 3. Press F1 to start profiling.
-- 4. Press F1 againt to stop profiling. Then input file name to save, and press ENTER.Default is profile.json.

local should_profile = vim.tbl_contains(vim.v.argv, "sal_profile")
if not should_profile then return end

require("profile").instrument_autocmds()

--[[
if should_profile:lower():match("^start") then
	require("profile").start("*")
else
	require("profile").instrument("*")
end
--]]
require("profile").instrument("*")

local function toggle_profile()
	local prof = require("profile")
	if prof.is_recording() then
		prof.stop()
		vim.ui.input({ prompt = "Save profile to:", completion = "file", default = "profile.json" }, function(filename)
			if filename then
				prof.export(filename)
				vim.notify(string.format("Wrote %s", filename))
			end
		end)
	else
		prof.start("*")
	end
end
vim.keymap.set("", "<f1>", toggle_profile)
