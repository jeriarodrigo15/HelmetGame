--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Packages = ReplicatedStorage:WaitForChild("Packages", 5)
local Knit = require(Packages:WaitForChild("Knit", 5))
local Janitor = require(Packages:WaitForChild("Janitor", 5))

-- Constants and Variables
local ANIMATION_ID = "rbxassetid://135617382036232"
local FREEZE_OFFSET = 0.05
local player = Players.LocalPlayer

local SeatController = Knit.CreateController({
	Name = "SeatController",
})

function SeatController:KnitStart()
	self.Janitor = Janitor.new()
	self.CurrentCharacter = nil

	if player.Character then
		self:onCharacterAdded(player.Character :: Model)
	end

	self.Janitor:Add(
		player.CharacterAdded:Connect(function(character)
			self:onCharacterAdded(character :: Model)
		end),
		"Disconnect"
	)
end

function SeatController:onCharacterAdded(character: Model)
	if self.CurrentCharacter == character then
		print("[SeatController] Aborted: Character already inicialized. ")
		return
	end
	self.CurrentCharacter = character

	local humanoid = if character then character:WaitForChild("Humanoid", 5) :: Humanoid else nil
	if not humanoid then
		print("[SeatController] Humanoid not founded")
		return
	end

	local CharacterJanitor = Janitor.new()
	CharacterJanitor:Add(
		character.AncestryChanged:Connect(function(_, parent)
			if not parent then
				print("Destroying (Character removed from game)")
				if self.CurrentCharacter == character then
					self.CurrentCharacter = nil
				end
				CharacterJanitor:Destroy()
			end
		end),
		"Disconnect"
	)

	CharacterJanitor:Add(
		humanoid.Seated:Connect(function(isSeated: boolean, seatPart: Instance?)
			if isSeated and seatPart then
				local SessionJanitor = Janitor.new()
				CharacterJanitor:Add(SessionJanitor, "Destroy", "CurrentSession")

				self:playAndFreezeAnimation(humanoid, SessionJanitor)
				print("Ok - Seated")
			else
				CharacterJanitor:Remove("CurrentSession")
				print("Ok - Stood up")
			end
		end),
		"Disconnect"
	)
end

function SeatController:playAndFreezeAnimation(Humanoid: Humanoid, SessionJanitor: any)
	local animator = Humanoid:WaitForChild("Animator") :: Animator
	local animation = Instance.new("Animation") :: Animation
	animation.AnimationId = ANIMATION_ID

	local animationTrack = animator:LoadAnimation(animation)

	SessionJanitor:Add(animationTrack, "Stop")
	SessionJanitor:Add(animation, "Destroy")

	animationTrack:Play()
	print("Animation played")

	task.spawn(function()
		local elapsed = 0
		while animationTrack.Length <= 0 and elapsed < 3 do
			elapsed += task.wait()
			print("Animation still loading")

			if not animationTrack.IsPlaying then
				warn("Animation stopped")
				return
			end
		end

		task.delay(animationTrack.Length - FREEZE_OFFSET, function()
			if animationTrack.IsPlaying then
				animationTrack:AdjustSpeed(0)
				print("Animation frozen")
			end
		end)
	end)
end

return SeatController
