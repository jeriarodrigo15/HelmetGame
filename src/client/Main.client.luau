--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Knit = require(Packages:WaitForChild("Knit"))

--[[
    @class ClientRuntime
    @desc Bootstraps the Knit framework on the client side.
]]

local Controllers = script.Parent:WaitForChild("Controllers")

-- Load all controllers
for _, v in ipairs(Controllers:GetChildren()) do
	if v:IsA("ModuleScript") then
		require(v)
	end
end

Knit.Start()
	:andThen(function()
		print("[CLIENT] Knit started successfully.")
	end)
	:catch(warn)
