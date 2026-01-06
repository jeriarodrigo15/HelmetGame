--!strict
--[[
    Identity: SeatController (Knit Client Controller)
    Description: Manages player seating logic, detecting when a player sits on or leaves a seat.
    Author: Gemini
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Knit = require(Packages:WaitForChild("Knit"))

-- Private variable (Local access only)
local _player = Players.LocalPlayer

local SeatController = Knit.CreateController({
	Name = "SeatController",
})

function SeatController:KnitStart()
	-- DEBUG: Confirming Knit initialization for this controller
	print("🚀 [SeatController] KnitStart: Initializing local seat detection...")

	-- CASE 1: Character already exists (e.g., script loaded after player spawned)
	if _player.Character then
		-- DEBUG: Character instance pre-exists, triggering setup immediately
		print("📦 [SeatController] Character detected upon initialization. Processing...")
		task.spawn(function()
			self:_onCharacterAdded(_player.Character :: Model)
		end)
	end

	-- CASE 2: Character added/respawned after script execution
	_player.CharacterAdded:Connect(function(character)
		-- DEBUG: New character model detected in Workspace
		print("♻️ [SeatController] CharacterAdded fired (New Character Instance).")
		self:_onCharacterAdded(character)
	end)
end

function SeatController:_onCharacterAdded(character: Model)
	-- DEBUG: Identifying character to ensure child instances are accessible
	print("🔍 [SeatController] Searching for Humanoid in: " .. character.Name)

	-- Wait for the Humanoid with a 5-second timeout to avoid infinite yield
	local humanoid = character:WaitForChild("Humanoid", 5) :: Humanoid?

	if not humanoid then
		-- DEBUG: Critical failure if Humanoid isn't found (e.g., character destroyed)
		print("❌ [SeatController] Error: Humanoid not found within timeout.")
		return
	end

	-- DEBUG: Success connecting listener to the Humanoid's state
	print("✅ [SeatController] Humanoid found. Connecting '.Seated' event listener.")

	-- Listen for seating state changes
	humanoid.Seated:Connect(function(isSeated: boolean, seatPart: Instance?)
		if isSeated then
			-- Determine seat name for debugging purposes
			local name = if seatPart then seatPart.Name else "Unknown Seat"
			-- DEBUG: Event triggered when character sits
			print("🪑 [SeatController] EVENT: Player is now SEATED on: " .. name)

			-- TODO: Insert animation logic here (e.g., Action priority animation)
		else
			-- DEBUG: Event triggered when character jumps or leaves seat
			print("🏃 [SeatController] EVENT: Player has STOOD UP.")
		end
	end)
end

return SeatController
