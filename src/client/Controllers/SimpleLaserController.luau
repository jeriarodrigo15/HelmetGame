--!strict
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

--[[
    @class SimpleLaserController
    @desc LÁSER NIVEL 1: Solo visual local, ultra simple.
]]

local Player = Players.LocalPlayer
local Connection: RBXScriptConnection? = nil

local function StartLaser(tool: Tool)
	local handle = tool:FindFirstChild("Handle") :: BasePart?
	local beam = if handle then handle:FindFirstChild("LaserBeam") :: Beam? else nil
	local att1 = if handle then handle:FindFirstChild("LaserA1") :: Attachment? else nil

	if not (beam and att1 and handle) then
		return
	end

	Connection = RunService.RenderStepped:Connect(function()
		beam.Enabled = true
		-- Dirección frontal simple (50 studs)
		att1.WorldPosition = handle.Position + (handle.CFrame.LookVector * 50)
	end)
end

local function StopLaser()
	if Connection then
		Connection:Disconnect()
		Connection = nil
	end
end

-- Monitor de equipamiento
Player.CharacterAdded:Connect(function(char)
	char.ChildAdded:Connect(function(child)
		if child:IsA("Tool") and child.Name == "Gun" then
			StartLaser(child)
		end
	end)
	char.ChildRemoved:Connect(function(child)
		if child.Name == "Gun" then
			StopLaser()
		end
	end)
end)

return {}
