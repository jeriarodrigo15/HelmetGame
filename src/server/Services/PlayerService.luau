--!strict

--[[
    @class PlayerService
    @author Tech Lead
    @desc Handles matchmaking lifecycle and countdown synchronization using Knit.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Knit = require(Packages.Knit)
local Janitor = require(Packages.Janitor)

local PlayerService = Knit.CreateService({
	Name = "PlayerService",
	Client = {
		Countdown = Knit.CreateProperty(0),
	},
})

-- Constants
local WARMUP_DURATION: number = 15
local HEIGHT_OFFSET: number = 4
local MIN_PLAYERS_REQUIRED: number = 1

-- Private logic
function PlayerService:SetCountdownValue(value: number): ()
	self.Client.Countdown:Set(value)
end

function PlayerService:ProcessMatchmaking(): ()
	if self.IsCounting or #Players:GetPlayers() < MIN_PLAYERS_REQUIRED then
		return
	end

	self.IsCounting = true
	print("[PlayerService] Matchmaking started.")

	task.spawn(function()
		for i = WARMUP_DURATION, 0, -1 do
			-- Re-check if players left during countdown
			if #Players:GetPlayers() < MIN_PLAYERS_REQUIRED then
				print("[PlayerService] Matchmaking cancelled: Not enough players.")
				self:SetCountdownValue(0)
				self.IsCounting = false
				return
			end

			self:SetCountdownValue(i)
			task.wait(1)
		end

		self:StartMatch()
	end)
end

function PlayerService:TeleportPlayerToZone(): ()
	print("[PlayerService] Starting teleportation sequence")
	local zone = Workspace:WaitForChild("Zone")
	if not zone or not zone:IsA("BasePart") then
		warn("[PlayerService] CRITICAL: 'Zone' block not found in Workspace!")
		return
	end

	local targetCFrame = zone.CFrame * CFrame.new(0, (zone.Size.Y / 2) + HEIGHT_OFFSET, 0)
	for _, player in Players:GetChildren() do
		local character = player:WaitForChild("Character", 5)
		if character and character:WaitForChild("HumanoidRootPart", 5) then
			character:PivotTo(targetCFrame)
		end
	end
	print("[PlayerService] All players teleported to Zone")
end

function PlayerService:StartMatch(): ()
	print("[PlayerService] Starting match and teleporting players...")
	-- Logic for teleportation or ECS world initialization goes here
	self.IsCounting = false
	self:SetCountdownValue(0)
end

function PlayerService:KnitStart(): ()
	-- Connect events to the Janitor
	self.Janitor:Add(
		Players.PlayerAdded:Connect(function()
			self:ProcessMatchmaking()
		end),
		"Disconnect"
	)

	-- Also check when someone leaves to cancel if necessary
	self.Janitor:Add(
		Players.PlayerRemoving:Connect(function()
			if #Players:GetPlayers() < MIN_PLAYERS_REQUIRED then
				self:SetCountdownValue(0)
			end
		end),
		"Disconnect"
	)
end

function PlayerService:KnitInit(): ()
	self.Janitor = Janitor.new()
	self.IsCounting = false
	print("[PlayerService] Initialized.")
end

return PlayerService
