--!strict

--[[
    @class CounterController
    @author Tech Lead
    @desc Manages countdown UI state using Knit and Janitor for memory management.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Knit = require(Packages.Knit)
local Janitor = require(Packages.Janitor)

-- Types
type self = {
	Janitor: any,
	CounterLabel: TextLabel?,
}

local CounterController = Knit.CreateController({
	Name = "CounterController",
})

-- Constants
local PLAYER = Players.LocalPlayer
local PLAYER_GUI = PLAYER:WaitForChild("PlayerGui")
local UI_PATH = { "Counter", "MainFrame", "CounterFrame", "CounterLabel" }

-- Private logic outside of KnitStart
function CounterController:SetupUI(): ()
	local current: any = PLAYER_GUI

	for _, name in ipairs(UI_PATH) do
		current = current:WaitForChild(name)
	end

	self.CounterLabel = current :: TextLabel
	print("[CounterController] UI References cached successfully.")
end

function CounterController:UpdateDisplay(seconds: number): ()
	if not self.CounterLabel then
		return
	end

	local label = self.CounterLabel :: TextLabel
	label.Text = if seconds > 0 then tostring(seconds) else "Waiting for players"

	print(string.format("[CounterController] Display updated: %d", seconds))
end

function CounterController:KnitStart(): ()
	local PlayerService = Knit.GetService("PlayerService")

	self:SetupUI()

	-- Cleanable observer pattern
	self.Janitor:Add(
		PlayerService.Countdown:Observe(function(seconds: number)
			self:UpdateDisplay(seconds)
		end),
		"Disconnect"
	)
end

function CounterController:KnitInit(): ()
	self.Janitor = Janitor.new()
	print("[CounterController] Initialized.")
end

function CounterController:Destroy(): ()
	self.Janitor:Destroy()
end

return CounterController
