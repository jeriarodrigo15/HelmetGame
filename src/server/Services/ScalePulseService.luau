--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Knit = require(Packages.Knit)

--[[
    @class ScalePulseService
    @desc Handles trigonometric scaling animations for environment primitives.
    @author Antigravity (Lead Architect)
]]
local ScalePulseService = Knit.CreateService({
	Name = "ScalePulseService",
	Client = {},
})

-- Performance Constants (AAA Standard: Tunable parameters at the top)
local BASE_SCALE = Vector3.new(4, 4, 4)
local PULSE_AMPLITUDE = 2 -- Maximum variance in size
local PULSE_SPEED = 3 -- Speed of the Sine wave

function ScalePulseService:KnitStart()
	print("ScalePulseService active. Initializing animation loop.")

	task.spawn(function()
		local timeAccumulator = 0

		while true do
			local deltaTime = task.wait()
			timeAccumulator += deltaTime

			self:ApplyPulse(timeAccumulator)
		end
	end)
end

function ScalePulseService:ApplyPulse(time: number)
	local workspace = game:GetService("Workspace")
	local pulsePart = workspace:FindFirstChild("PulsePart") :: Part?

	if pulsePart and pulsePart:IsA("Part") then
		-- Mathematical animation: Sine wave provides smooth oscillation
		-- Formula: Offset = Amplitude * sin(Time * Speed)
		local scaleOffset = math.sin(time * PULSE_SPEED) * PULSE_AMPLITUDE
		local newScale = BASE_SCALE + Vector3.new(scaleOffset, scaleOffset, scaleOffset)

		pulsePart.Size = newScale
	else
		-- Optimization: We only warn once or occasionally in production to avoid log spam
		-- For learning: We keep it active.
	end
end

return ScalePulseService
