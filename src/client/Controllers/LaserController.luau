--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Knit = require(Packages:WaitForChild("Knit"))

--[[
    @class LaserController
    @desc Handles local weapon laser rendering and network replication.
    @logic Origin: LaserA0, Direction: -flare.CFrame.LookVector (Outward)
]]

local LaserController = Knit.CreateController({
	Name = "LaserController",
})

local Player = Players.LocalPlayer
local CurrentTool: Tool? = nil
local LaserBeams = {} -- Tracking other players' laser beams

-- LOCAL CACHE
local CachedBeam: Beam? = nil
local CachedAtt0: Attachment? = nil
local CachedAtt1: Attachment? = nil
local CachedFlare: BasePart? = nil

function LaserController:KnitStart()
	local LaserService = Knit.GetService("LaserService")

	-- Receive updates from other players
	LaserService.LaserSyncSignal:Connect(function(otherPlayer, targetPos)
		if otherPlayer == Player then
			return
		end
		self:UpdateOtherPlayerLaser(otherPlayer, targetPos)
	end)

	-- Robust Character Monitoring
	local function MonitorCharacter(character: Model)
		local function CheckForTool()
			local tool = character:FindFirstChild("Gun") :: Tool?
			if tool then
				if CurrentTool ~= tool then
					CurrentTool = tool
					self:StartLocalLaser()
					print("🔫 Arma detectada!")
				end
			else
				if CurrentTool then
					self:StopLocalLaser()
					CurrentTool = nil
					print("🔫 Arma desequipada")
				end
			end
		end

		character.ChildAdded:Connect(CheckForTool)
		character.ChildRemoved:Connect(CheckForTool)
		CheckForTool() -- Inital check
	end

	if Player.Character then
		MonitorCharacter(Player.Character)
	end
	Player.CharacterAdded:Connect(MonitorCharacter)

	-- Network Update Loop (10 Hz)
	task.spawn(function()
		while true do
			task.wait(0.1)
			if CurrentTool and CachedAtt0 and CachedFlare then
				local rayOrigin = CachedAtt0.WorldPosition
				-- Probamos LookVector positivo primero si el negativo falló
				local rayDirection = CachedFlare.CFrame.LookVector * 500
				local params = RaycastParams.new()
				params.FilterDescendantsInstances = { Player.Character }
				params.FilterType = Enum.RaycastFilterType.Exclude

				local result = workspace:Raycast(rayOrigin, rayDirection, params)
				local hitPos = if result then result.Position else rayOrigin + rayDirection

				LaserService:UpdateLaser(hitPos)
			end
		end
	end)
end

function LaserController:UpdateOtherPlayerLaser(otherPlayer: Player, targetPos: Vector3)
	local char = otherPlayer.Character
	if not char then
		return
	end

	local tool = char:FindFirstChild("Gun")
	if not tool then
		return
	end

	-- Búsqueda recursiva (FindFirstChild con true es recursivo)
	local beam = tool:FindFirstChild("LaserBeam", true) :: Beam?
	local att1 = tool:FindFirstChild("LaserA1", true) :: Attachment?

	if beam and att1 then
		beam.Enabled = true
		att1.WorldPosition = targetPos
		LaserBeams[otherPlayer] = beam
	end
end

function LaserController:StartLocalLaser()
	local tool = CurrentTool
	if not tool then
		return
	end

	-- BÚSQUEDA RECURSIVA CON REINTENTO (Protocolo de Replicación)
	local function GetComponents()
		CachedBeam = tool:FindFirstChild("LaserBeam", true) :: Beam?
		CachedAtt0 = tool:FindFirstChild("LaserA0", true) :: Attachment?
		CachedAtt1 = tool:FindFirstChild("LaserA1", true) :: Attachment?
		CachedFlare = (tool:FindFirstChild("Flare", true) or tool:FindFirstChild("Handle", true)) :: BasePart?
	end

	GetComponents()
	if not (CachedBeam and CachedAtt0 and CachedAtt1 and CachedFlare) then
		task.wait(0.2) -- Esperamos a que los hijos se repliquen
		GetComponents()
	end

	-- Diagnóstico Final
	if not  then
		warn("❌ [Láser] Falta LaserBeam")
	end
	if not CachedAtt0 then
		warn("❌ [Láser] Falta LaserA0")
	end
	if not CachedAtt1 then
		warn("❌ [Láser] Falta LaserA1")
	end
	if not CachedFlare then
		warn("❌ [Láser] Falta Flare o Handle")
	end

	if not (CachedBeam and CachedAtt0 and CachedAtt1 and CachedFlare) then
		return
	end

	-- Propiedades de emergencia (Forzamos visibilidad por si acaso)
	CachedBeam.Width0 = 0.1
	CachedBeam.Width1 = 0.1
	CachedBeam.Color = ColorSequence.new(Color3.new(1, 0, 0))
	CachedBeam.FaceCamera = true
	CachedBeam.ZOffset = 0.05 -- Para que no parpadee contra paredes

	print("✨ Láser configurado y buscando objetivo...")

	RunService:BindToRenderStep("StandaloneLaser", Enum.RenderPriority.Last.Value, function()
		if not (CurrentTool == tool and CachedBeam and CachedAtt0 and CachedAtt1 and CachedFlare) then
			return
		end

		CachedBeam.Enabled = true
		local rayOrigin = CachedAtt0.WorldPosition
		-- PROBAMOS LOOKVECTOR POSITIVO (Confirmarás si apunta afuera)
		local rayDirection = CachedFlare.CFrame.LookVector * 500
		local params = RaycastParams.new()
		params.FilterDescendantsInstances = { Player.Character }
		params.FilterType = Enum.RaycastFilterType.Exclude

		local result = workspace:Raycast(rayOrigin, rayDirection, params)
		CachedAtt1.WorldPosition = if result then result.Position else rayOrigin + rayDirection
	end)
end

function LaserController:StopLocalLaser()
	RunService:UnbindFromRenderStep("StandaloneLaser")
	if CachedBeam then
		CachedBeam.Enabled = false
	end
	CachedBeam, CachedAtt0, CachedAtt1, CachedFlare = nil, nil, nil, nil
end

function LaserController:KnitInit() end

return LaserController
