--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Knit = require(Packages:WaitForChild("Knit"))

-- Variable privada (Solo este script la conoce)
local _player = Players.LocalPlayer

local SeatController = Knit.CreateController({
	Name = "SeatController",
})

function SeatController:KnitStart()
	print("🚀 [SeatController] KnitStart: Iniciando...")

	-- CASO 1: El personaje ya existe al cargar el script
	if _player.Character then
		print("📦 [SeatController] Personaje detectado al inicio. Procesando...")
		task.spawn(function()
			self:_onCharacterAdded(_player.Character :: Model)
		end)
	end

	-- CASO 2: El personaje carga después o revive (Respawn)git
	_player.CharacterAdded:Connect(function(character)
		print("♻️ [SeatController] CharacterAdded disparado (Nuevo personaje).")
		self:_onCharacterAdded(character)
	end)
end

function SeatController:_onCharacterAdded(character: Model)
	print("🔍 [SeatController] Buscando Humanoid en: " .. character.Name)

	local humanoid = character:WaitForChild("Humanoid", 5) :: Humanoid?

	if not humanoid then
		print("❌ [SeatController] Error: No se encontró Humanoid a tiempo.")
		return
	end

	print("✅ [SeatController] Humanoid encontrado. Conectando evento .Seated")

	-- Escuchar cuando el estado de sentado cambia
	humanoid.Seated:Connect(function(isSeated: boolean, seatPart: Instance?)
		if isSeated then
			local name = if seatPart then seatPart.Name else "Asiento Desconocido"
			print("🪑 [SeatController] EVENTO: El jugador se ha SENTADO en: " .. name)
		else
			print("🏃 [SeatController] EVENTO: El jugador se ha LEVANTADO.")
		end
	end)
end

return SeatController
