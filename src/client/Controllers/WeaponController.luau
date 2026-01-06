--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ContentProvider = game:GetService("ContentProvider")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Knit = require(Packages:WaitForChild("Knit"))

local RunService = game:GetService("RunService")

local WeaponController = Knit.CreateController({
	Name = "WeaponController",
})

-- Performance Config: IDs de las imágenes del fogonazo
local FLASH_IMAGES = {
	"rbxassetid://103740493",
	"rbxassetid://103804266",
	"rbxassetid://103804383",
}

local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()
local CurrentTool: Tool? = nil
local InputConnection: RBXScriptConnection? = nil
local RecoilTrack: AnimationTrack? = nil

-- LÁSER SIMPLE (LEVEL 1)

function WeaponController:KnitStart()
	local WeaponService = Knit.GetService("WeaponService")

	-- El sistema de láser ahora se gestiona en LaserController.luau

	-- Pre-cargar imágenes para evitar lag visual
	local tempImages = {}
	for _, id in ipairs(FLASH_IMAGES) do
		local img = Instance.new("ImageLabel")
		img.Image = id
		table.insert(tempImages, img)
	end
	ContentProvider:PreloadAsync(tempImages)

	local function MonitorCharacter(character: Model)
		character.ChildAdded:Connect(function(child)
			if child:IsA("Tool") and child.Name == "Gun" then
				self:OnEquip(child)
			end
		end)
		character.ChildRemoved:Connect(function(child)
			if child == CurrentTool then
				self:OnUnequip()
			end
		end)
	end

	if Player.Character then
		MonitorCharacter(Player.Character)
	end
	Player.CharacterAdded:Connect(MonitorCharacter)

	-- LOOP DE RED: Enviar posición del láser al servidor
	task.spawn(function()
		while true do
			task.wait(0.1) -- Sincronización promediada
			if CurrentTool then
				local flare = CurrentTool:FindFirstChild("Flare") :: BasePart?
				local att0 = CurrentTool:FindFirstChild("LaserA0", true) :: Attachment?

				if flare and att0 then
					-- DIRECCIÓN CORRECTA: -LookVector (hacia afuera)
					local rayOrigin = att0.WorldPosition
					local rayDirection = -flare.CFrame.LookVector * 500
					local params = RaycastParams.new()
					params.FilterDescendantsInstances = { Player.Character }
					params.FilterType = Enum.RaycastFilterType.Exclude

					local result = workspace:Raycast(rayOrigin, rayDirection, params)
					local hitPos = if result then result.Position else rayOrigin + rayDirection

					-- Enviamos la posición al servidor para replicar
					WeaponService:UpdateLaser(hitPos)
				end
			end
		end
	end)
end

-- El láser ahora se configura MANUALLY en el Explorer (Regla de Oro).
-- No instanciamos nada visual por código.

function WeaponController:UpdateOtherPlayerLaser(otherPlayer: Player, targetPos: Vector3)
	local char = otherPlayer.Character
	if not char then
		return
	end

	local tool = char:FindFirstChild("Gun")
	local handle = if tool then tool:FindFirstChild("Handle") :: BasePart? else nil
	if not handle then
		return
	end

	-- Búsqueda recursiva: Funciona si está en el Tool o en el Handle
	local beam = tool:FindFirstChild("LaserBeam", true) :: Beam?
	local att1 = tool:FindFirstChild("LaserA1", true) :: Attachment?

	if beam and att1 then
		beam.Enabled = true
		att1.WorldPosition = targetPos
		LaserBeams[otherPlayer] = { Beam = beam, Att = att1 }
	end
end

function WeaponController:OnEquip(tool: Tool)
	CurrentTool = tool
	Player.CameraMode = Enum.CameraMode.LockFirstPerson

	local handle = tool:FindFirstChild("Handle") :: BasePart?
	if handle then
		-- REGLA: Reproducir ambos sonidos de equipamiento
		local s1 = handle:FindFirstChild("EquipSound") :: Sound?
		local s2 = handle:FindFirstChild("EquipSound2") :: Sound?
		if s1 then
			s1:Play()
		end
		if s2 then
			s2:Play()
		end

		-- Búsqueda recursiva de componentes manuales
		local beam = tool:FindFirstChild("LaserBeam", true) :: Beam?
		local att0 = tool:FindFirstChild("LaserA0", true) :: Attachment?
		local att1 = tool:FindFirstChild("LaserA1", true) :: Attachment?

		if beam then
			beam.Enabled = true
		end

		-- Loop local para mover el láser a tiempo real (60 FPS)
		RunService:BindToRenderStep("FlashLaser", Enum.RenderPriority.Last.Value, function()
			local flare = tool:FindFirstChild("Flare") :: BasePart?
			-- El rayo nace en LaserA0 (Punta del cañón)
			if att0 and att1 and flare then
				local rayOrigin = att0.WorldPosition
				local rayDirection = -flare.CFrame.LookVector * 500 -- DIRECCIÓN CORRECTA (hacia afuera)
				local params = RaycastParams.new()
				params.FilterDescendantsInstances = { Player.Character }
				params.FilterType = Enum.RaycastFilterType.Exclude

				local result = workspace:Raycast(rayOrigin, rayDirection, params)
				att1.WorldPosition = if result then result.Position else rayOrigin + rayDirection
			end
		end)
	end

	local humanoid = Player.Character:FindFirstChildOfClass("Humanoid")
	local recoilAnim = tool:FindFirstChild("Recoil") :: Animation?
	if humanoid and recoilAnim then
		RecoilTrack = humanoid:LoadAnimation(recoilAnim)
	end

	if InputConnection then
		InputConnection:Disconnect()
	end
	InputConnection = UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.UserInputType == Enum.UserInputType.MouseButton1 then
			self:Shoot()
		end
	end)
end

function WeaponController:OnUnequip()
	CurrentTool = nil
	Player.CameraMode = Enum.CameraMode.Classic
	RunService:UnbindFromRenderStep("FlashLaser")

	if InputConnection then
		InputConnection:Disconnect()
	end
	if RecoilTrack then
		RecoilTrack:Stop()
	end
	-- El láser se desactivará en el siguiente loop de red o por el sistema de detección
end

function WeaponController:Shoot()
	if not CurrentTool then
		return
	end
	local handle = CurrentTool:FindFirstChild("Handle") :: BasePart?
	local flare = CurrentTool:FindFirstChild("Flare") :: BasePart?
	if not handle then
		return
	end

	local fireSound = handle:FindFirstChild("FireSound") :: Sound?
	if fireSound then
		fireSound:Play()
	end
	if RecoilTrack then
		RecoilTrack:Play()
	end

	-- ACTIVACIÓN DEL EFECTO FLARE (Animación de imágenes)
	if flare then
		local bgui = flare:FindFirstChild("BillboardGui") :: BillboardGui?
		local imgLabel = if bgui then bgui:FindFirstChild("ImageLabel") :: ImageLabel? else nil
		if bgui and imgLabel then
			task.spawn(function()
				bgui.Enabled = true
				for _, id in ipairs(FLASH_IMAGES) do
					imgLabel.Image = id
					task.wait(0.02) -- Ciclo rápido de fogonazo
				end
				bgui.Enabled = false
			end)
		end
	end

	local start = handle.Position
	local dir = (Mouse.Hit.Position - start).Unit * 500
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = { Player.Character }
	params.FilterType = Enum.RaycastFilterType.Exclude

	local res = workspace:Raycast(start, dir, params)
	Knit.GetService("WeaponService"):RequestShoot(
		if res and res.Instance.Parent then res.Instance.Parent:FindFirstChildOfClass("Humanoid") else nil,
		if res then res.Position else start + dir
	)
end

function WeaponController:KnitInit() end

return WeaponController
