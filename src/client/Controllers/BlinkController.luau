--!strict
--[=[
    @class BlinkController
    @client
    Handles the visual effect of the eyes closing/opening and the REM (Rapid Eye Movement)
    animation logic for the player.
]=]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Knit = require(Packages:WaitForChild("Knit"))

local BlinkController = Knit.CreateController({
	Name = "BlinkController",
})

-- Types
type EyelidFrames = {
	Top: Frame,
	Bottom: Frame,
}

-- Constants
local REM_INTENSITY = 0.02 -- Percentage of screen size for jitter
local REM_SPEED = 0.1 -- Seconds between jitter updates
local TWEEN_INFO = TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

-- Private variables
local _player = Players.LocalPlayer
local _playerGui = _player:WaitForChild("PlayerGui")
local _blinkGui: ScreenGui?
local _lids: EyelidFrames?
local _isEyesClosed = false
local _remConnection: RBXScriptConnection?
local _isInitialized = false

--[=[
    @private
    Initializes the UI references and forces an initial "Open" state.
    Enforces correct properties (Position, AnchorPoint, ZIndex, etc.) to avoid manual errors.
]=]
function BlinkController:_setupUI()
	local blinkGui = _playerGui:WaitForChild("BlinkGui", 10) :: ScreenGui?
	if not blinkGui then
		warn("[BlinkController] BlinkGui not found in PlayerGui! Make sure you created it in StarterGui.")
		return
	end

	-- Force ScreenGui properties
	blinkGui.IgnoreGuiInset = true
	blinkGui.Enabled = true

	local topLid = blinkGui:WaitForChild("TopLid", 5) :: Frame?
	local bottomLid = blinkGui:WaitForChild("BottomLid", 5) :: Frame?

	if not topLid or not bottomLid then
		warn("[BlinkController] Lids (TopLid/BottomLid) not found in BlinkGui! Check hierarchy.")
		return
	end

	_blinkGui = blinkGui
	_lids = {
		Top = topLid,
		Bottom = bottomLid,
	}

	-- Enforce properties via code for "AAA" reliability
	topLid.AnchorPoint = Vector2.new(0.5, 0)
	topLid.Position = UDim2.fromScale(0.5, 0)
	topLid.Size = UDim2.fromScale(1, 0)
	topLid.BackgroundColor3 = Color3.new(0, 0, 0)
	topLid.ZIndex = 100
	topLid.BorderSizePixel = 0

	bottomLid.AnchorPoint = Vector2.new(0.5, 1)
	bottomLid.Position = UDim2.fromScale(0.5, 1)
	bottomLid.Size = UDim2.fromScale(1, 0)
	bottomLid.BackgroundColor3 = Color3.new(0, 0, 0)
	bottomLid.ZIndex = 100
	bottomLid.BorderSizePixel = 0

	print("[BlinkController] UI Properties Enforced Successfully.")
	_isInitialized = true
end

--[=[
    Starts the REM animation loop when eyes are closed.
]=]
function BlinkController:_startREM()
	if _remConnection or not _lids then
		return
	end

	local lastUpdate = 0
	_remConnection = RunService.RenderStepped:Connect(function()
		local now = os.clock()
		if now - lastUpdate < REM_SPEED then
			return
		end
		lastUpdate = now

		-- Logic: Apply a small random offset to the position of the lids
		local offsetY = (math.random() - 0.5) * REM_INTENSITY

		local lids = _lids
		if lids then
			-- Ensure positions are correct based on corrected AnchorPoints (Top: 0.5, 0 | Bottom: 0.5, 1)
			lids.Top.Position = UDim2.fromScale(0.5, 0 + offsetY)
			lids.Bottom.Position = UDim2.fromScale(0.5, 1 + offsetY)
		end
	end)
end

--[=[
    Stops the REM animation loop.
]=]
function BlinkController:_stopREM()
	if _remConnection then
		_remConnection:Disconnect()
		_remConnection = nil
	end

	-- Reset positions
	if _lids then
		_lids.Top.Position = UDim2.fromScale(0.5, 0)
		_lids.Bottom.Position = UDim2.fromScale(0.5, 1)
	end
end

--[=[
    Closes the player's eyes.
]=]
function BlinkController:CloseEyes(duration: number?)
	if not _isInitialized then
		local timeout = 5
		local elapsed = 0
		while not _isInitialized and elapsed < timeout do
			elapsed += task.wait(0.1)
		end
		if not _isInitialized then
			return
		end
	end

	if _isEyesClosed or not _lids then
		return
	end
	_isEyesClosed = true

	print("[BlinkController] Closing Eyes...")

	local info = duration and TweenInfo.new(duration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out) or TWEEN_INFO

	local topTween = TweenService:Create(_lids.Top, info, {
		Size = UDim2.fromScale(1, 0.5),
	})

	local bottomTween = TweenService:Create(_lids.Bottom, info, {
		Size = UDim2.fromScale(1, 0.5),
	})

	topTween:Play()
	bottomTween:Play()

	topTween.Completed:Wait()
	if _isEyesClosed then
		self:_startREM()
	end
end

--[=[
    Opens the player's eyes.
]=]
function BlinkController:OpenEyes(duration: number?)
	if not _isInitialized or not _lids then
		return
	end
	if not _isEyesClosed then
		return
	end
	_isEyesClosed = false

	print("[BlinkController] Opening Eyes...")

	self:_stopREM()

	local info = duration and TweenInfo.new(duration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out) or TWEEN_INFO

	local topTween = TweenService:Create(_lids.Top, info, {
		Size = UDim2.fromScale(1, 0),
	})

	local bottomTween = TweenService:Create(_lids.Bottom, info, {
		Size = UDim2.fromScale(1, 0),
	})

	topTween:Play()
	bottomTween:Play()
end

--[=[
    Performs a quick blink.
]=]
function BlinkController:Blink()
	self:CloseEyes(0.1)
	task.wait(0.1)
	self:OpenEyes(0.1)
end

function BlinkController:KnitStart()
	-- Auto-test after 2 seconds: Quick Blink + Long Closing
	task.delay(2, function()
		print("[BlinkController] Performing Test Blink")
		self:Blink()
		task.wait(1)
		print("[BlinkController] Closing eyes for 5 seconds")
		self:CloseEyes()
		task.wait(5)
		self:OpenEyes()
	end)
end

function BlinkController:KnitInit()
	task.spawn(function()
		self:_setupUI()
	end)
end

return BlinkController
