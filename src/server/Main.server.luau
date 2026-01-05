--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Knit = require(Packages.Knit)

--[[
    @class ServerRuntime
    @desc Bootstraps the Knit framework on the server side.
]]

-- Add services folder reference
local Services = script.Parent:WaitForChild("Services")

-- Load all services
for _, v in Services:GetChildren() do
	if v:IsA("ModuleScript") then
		require(v)
	end
end

Knit.Start()
	:andThen(function()
		print("[SERVER] Knit started")
	end)
	:catch(warn)
