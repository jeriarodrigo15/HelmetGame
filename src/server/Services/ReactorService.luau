--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Knit = require(Packages.Knit)

--[[
    @class ReactorService
    @desc Synchronizes scale, rotation, and color properties using high-performance procedurals.
    @author Antigravity (Lead Architect)
]]
local ReactorService = Knit.CreateService({
	Name = "ReactorService",
	Client = {},
})

-- Configuration Constants
local BASE_SCALE = Vector3.new(4, 4, 4)
local PULSE_AMPLITUDE = 2.5
local PULSE_SPEED = 2.5
local ROTATION_SPEED = 180 -- Degrees per second

-- Color Palettes (Professional HSL usage)
local MIN_COLOR = Color3.fromRGB(0, 170, 255) -- Cyan (Relaxed)
local MAX_COLOR = Color3.fromRGB(255, 0, 100) -- Magenta (Active)

function ReactorService:KnitStart()
	print("Reactor core online. Systems synchronized.")

	task.spawn(function()
		local timeAccumulator = 0

		while true do
			local deltaTime = task.wait()
			timeAccumulator += deltaTime

			self:UpdateReactor(timeAccumulator, deltaTime)
		end
	end)
end

function ReactorService:UpdateReactor(time: number, dt: number)
	local workspace = game:GetService("Workspace")
	local parts = workspace:GetChildren()

	for _, part in parts do
		if part.Name == "PulsePart" and part:IsA("Part") then
			-- 1. SYNCHRONIZED SCALE (Sine Drive)
			local alpha = (math.sin(time * PULSE_SPEED) + 1) / 2 -- Normalized 0 to 1
			local scaleOffset = alpha * PULSE_AMPLITUDE
			part.Size = BASE_SCALE + Vector3.new(scaleOffset, scaleOffset, scaleOffset)

			-- 2. DYNAMIC COLOR TINT (Lerp base on pulse intensity)
			-- Smoothly transitions from Cyan to Magenta as it grows
			part.Color = MIN_COLOR:Lerp(MAX_COLOR, alpha)

			-- 3. ROTATION (Linear velocity)
			-- Note: For anchored parts, we CFrame directly.
			part.CFrame = part.CFrame * CFrame.Angles(0, math.rad(ROTATION_SPEED * dt), 0)

			-- 4. GLOW INTENSITY (Bonus: Transparency modulation)
			-- It becomes more opaque (glowing harder) when largest
			part.Transparency = 0.2 + (1 - alpha) * 0.4
		end
	end
end

return ReactorService
