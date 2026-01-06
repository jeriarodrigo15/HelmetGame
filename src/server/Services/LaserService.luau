--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Knit = require(Packages:WaitForChild("Knit"))

--[[
    @class LaserService
    @desc Dedicated service for real-time laser pointer replication.
]]

local LaserService = Knit.CreateService({
	Name = "LaserService",
	Client = {
		LaserSyncSignal = Knit.CreateSignal(), -- Broadcaster for laser positions
	},
})

function LaserService:KnitStart()
	print("🔴 LaserService started. Ready for synchronization.")
end

function LaserService.Client:UpdateLaser(player: Player, targetPos: Vector3)
	-- Relay the position to everyone else
	self.LaserSyncSignal:FireAll(player, targetPos)
end

function LaserService:KnitInit() end

return LaserService
