--!strict
--[=[
    @class SeatController
    @client
    Handles custom animations when the player sits in a Seat.
    Designed for R6 avatars as requested.
]=]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Knit = require(Packages:WaitForChild("Knit"))

local SeatController = Knit.CreateController({
	Name = "SeatController",
})

-- Constants
local CUSTOM_ANIM_ID = "rbxassetid://135617382036232"

-- Private variables
local _player = Players.LocalPlayer
local _sittingTrack: AnimationTrack?

--[=[
    @private
    Initializes the animation logic for a new character.
]=]
function SeatController:_setupCharacter(character: Model)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	local animator = humanoid:WaitForChild("Animator") :: Animator

	-- Load Animation
	local animation = Instance.new("Animation")
	animation.Name = "SeatCustomAnim"
	animation.AnimationId = CUSTOM_ANIM_ID

	local track = animator:LoadAnimation(animation)
	track.Priority = Enum.AnimationPriority.Action -- High priority to override default Sit anim
	track.Looped = false

	-- Connect Seated event
	humanoid.Seated:Connect(function(isSeated: boolean, seatPart: Instance?)
		if isSeated then
			print("[SeatController] Player is seated. Playing animation.")
			track:Play() -- 0.1s fade in
		end
	end)

	-- Clean up on death
	humanoid.Died:Connect(function()
		track:Stop()
	end)
end

function SeatController:KnitStart()
	print("[SeatController] Started.")

	-- Handle current character if exists
	if _player.Character then
		task.spawn(function()
			self:_setupCharacter(_player.Character :: Model)
		end)
	end

	-- Handle respawns
	_player.CharacterAdded:Connect(function(character)
		self:_setupCharacter(character)
	end)
end

function SeatController:KnitInit()
	-- No specific initialization needed for this controller
end

return SeatController
