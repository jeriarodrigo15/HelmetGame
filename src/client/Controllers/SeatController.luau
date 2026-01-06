--!strict
--[=[
    @class SeatController
    @client
    Módulo 1: Detección de Estado de Asiento.
    Este controlador gestiona la detección de cuando el jugador se sienta o se levanta.
]=]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Knit = require(Packages:WaitForChild("Knit"))

-- Variables privadas
local _player = Players.LocalPlayer

local SeatController = Knit.CreateController({
	Name = "SeatController",
})

function SeatController:KnitStart()
	print("[SeatController] Initialized.")

	-- Manejo de persistencia: Detectar personaje actual y futuros respawns.
	if _player.Character then
		task.spawn(function()
			self:_onCharacterAdded(_player.Character :: Model)
		end)
	end

	_player.CharacterAdded:Connect(function(character)
		self:_onCharacterAdded(character)
	end)
end

function SeatController:_onCharacterAdded(character: Model)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid

	-- Luau Engineering: Conectamos al evento nativo .Seated
	-- Este evento es más eficiente que pollear propiedades.
	humanoid.Seated:Connect(function(isSeated: boolean, seatPart: Instance?)
		if isSeated then
			-- Business Logic: El jugador se ha sentado.
			-- seatPart nos dice exactamente en qué objeto.
			local seatName = if seatPart then seatPart.Name else "Unknown Seat"
			print(string.format("[SeatController] Player SAT DOWN on: %s", seatName))
		else
			-- Business Logic: El jugador se ha levantado.
			print("[SeatController] Player STOOD UP.")
		end
	end)
end

return SeatController
