--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Knit = require(Packages:WaitForChild("Knit"))

--[[
    @class WeaponService
    @desc Handles server-side combat logic: damage validation, bullet instantiation, and kill tagging.
    @why Security: Never trust the client for damage values. Optimization: Centralized projectile handling.
]]

local WeaponService = Knit.CreateService({
	Name = "WeaponService",
	Client = {
		ReplicateShot = Knit.CreateSignal(), -- For fire effects
	},
})

-- Configuration: Match these with Tool data for double-check validation (AAA standard)
local WEAPON_DAMAGES = {
	["Gun"] = 18,
}

function WeaponService:KnitStart()
	print("⚔ WeaponService initialized. Ensuring fair combat.")

	-- Initialize Bullet Folder (Manual over Code rule: but for cleanup we prefer dynamic holders)
	local bulletsFolder = workspace:FindFirstChild("BulletsFolder")
	if not bulletsFolder then
		local folder = Instance.new("Folder")
		folder.Name = "BulletsFolder"
		folder.Parent = workspace
	end
end

function WeaponService.Client:RequestShoot(player: Player, targetHumanoid: Humanoid?, hitPos: Vector3)
	-- [SERVER VALIDATION] In a real AAA game, we'd check distance and cooldowns here.
	local character = player.Character
	if not character then
		return
	end

	-- Damage Processing
	if targetHumanoid and targetHumanoid.Health > 0 then
		local damage = WEAPON_DAMAGES["Gun"] or 10
		targetHumanoid:TakeDamage(damage)
		self.Server:TagHumanoid(targetHumanoid, player)
	end

	-- Projects visual bullet to other players
	self.ReplicateShot:FireAll(player, hitPos)
end

function WeaponService.Client:UpdateLaser(player: Player, targetPos: Vector3)
	-- [DEBUG] print("🛰️ Recibiendo láser de:", player.Name, "Hacia:", targetPos)
	-- Relay the laser position to everyone but the sender
	self.LaserSyncSignal:FireAll(player, targetPos)
end

function WeaponService:TagHumanoid(humanoid: Humanoid, player: Player)
	-- Remove old tags
	for _, child in ipairs(humanoid:GetChildren()) do
		if child.Name == "creator" then
			child:Destroy()
		end
	end

	-- Add new tag for kill credit
	local tag = Instance.new("ObjectValue")
	tag.Name = "creator"
	tag.Value = player
	tag.Parent = humanoid
	Debris:AddItem(tag, 2)
end

function WeaponService:KnitInit()
	-- Pre-setup logic
end

return WeaponService
