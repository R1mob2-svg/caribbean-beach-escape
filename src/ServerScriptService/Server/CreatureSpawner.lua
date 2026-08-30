--!strict
-- CreatureSpawner: spawns killer crabs from sand holes, ocean creatures from
-- the surf, and swashbuckling pirate patrols along the shore. All models are
-- built from original parts (no ripped assets). Server-authoritative.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local GameServer = script.Parent:WaitForChild("GameServer")

local CreatureSpawner = {}
CreatureSpawner.__index = CreatureSpawner

type CreatureState = {
	trackingPlayers: boolean,
}

local CRAB_RED = Color3.fromRGB(200, 40, 40)
local OCTO_PURPLE = Color3.fromRGB(180, 60, 180)
local PIRATE_RED = Color3.fromRGB(40, 40, 50)
local PIRATE_SKIN = Color3.fromRGB(228, 175, 128)

function CreatureSpawner.new(): CreatureSpawner
	local self = setmetatable({}, CreatureSpawner)
	self._models = {}
	self._scripts = {}
	return self
end

-- Build a reusable creature model (original primitive parts).
function CreatureSpawner:buildModels()
	-- KILLER CRAB --------------------------------------------
	local crab = Instance.new("Model")
	crab.Name = GameConfig.Creatures.Crab.ModelName
	local crabBody = part("Body", Vector3.new(2.2, 1, 1.4), CRAB_RED)
	crabBody.Parent = crab
	local crabHead = part("Head", Vector3.new(1.4, 0.9, 0.8), CRAB_RED)
	crabHead.Position = crabBody.Position + Vector3.new(1.6, 0.2, 0)
	crabHead.Parent = crab
	for _, x in ipairs({ -1.1, 1.1 }) do
		local claw = part("Claw", Vector3.new(1.0, 0.7, 0.7), CRAB_RED)
		claw.Position = crabBody.Position + Vector3.new(x, -0.2, 0)
		claw.Parent = crab
	end
	crab.PrimaryPart = crabBody
	crab.Parent = Workspace
	self._models.Crab = crab

	-- OCEAN OCTOPUS ------------------------------------------
	local octo = Instance.new("Model")
	octo.Name = GameConfig.Creatures.Octopus.ModelName
	local octoBody = part("Body", Vector3.new(2.4, 1.6, 1.6), OCTO_PURPLE)
	octoBody.Parent = octo
	for i = 1, 5 do
		local leg = part("Leg", Vector3.new(1.8, 0.6, 0.6), OCTO_PURPLE)
		leg.CFrame = octoBody.CFrame * CFrame.new(0, -0.8, -1.2) * CFrame.Angles(0, (i - 2) * 0.7, math.rad(-30))
		leg.Parent = octo
	end
	octo.PrimaryPart = octoBody
	octo.Parent = Workspace
	self._models.Octopus = octo

	-- PIRATE PATROL ------------------------------------------
	local pirate = Instance.new("Model")
	pirate.Name = GameConfig.Creatures.Pirate.ModelName
	local pirateBody = part("Body", Vector3.new(1.2, 2.4, 1), PIRATE_RED)
	pirateBody.Parent = pirate
	local pirateHead = part("Head", Vector3.new(0.9, 0.9, 0.9), PIRATE_SKIN)
	pirateHead.Position = pirateBody.Position + Vector3.new(0, 1.6, 0)
	pirateHead.Parent = pirate
	local hat = part("Hat", Vector3.new(0.6, 0.6, 0.6), Color3.fromRGB(140, 40, 40))
	hat.Position = pirateHead.Position + Vector3.new(0, 0.8, 0)
	hat.Parent = pirate
	local cutlass = part("Cutlass", Vector3.new(0.2, 0.2, 1.5), Color3.fromRGB(200, 200, 200))
	cutlass.Position = pirateBody.Position + Vector3.new(0.9, 0, 0)
	cutlass.Parent = pirate
	pirate.PrimaryPart = pirateBody
	pirate.Parent = Workspace
	self._models.Pirate = pirate
end

local function part(name: string, size: Vector3, color: Color3): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Anchored = true
	p.CanCollide = false
	p.Material = Enum.Material.SmoothPlastic
	return p
end

-- Begin all recurring hazard behaviour.
function CreatureSpawner:start()
	self:_spawnPirates()
	self:_crabLoop()
	self:_octopusLoop()
end

-- Crabs: pick a sand hole zone at or ahead of the furthest player, erupt a crab.
function CreatureSpawner:_crabLoop()
	local last = 0
	RunService.Heartbeat:Connect(function()
		-- do nothing here; use task-based scheduling driven by the loop below
	end)
end

-- We use explicit loops with task.wait for clarity and testability.
-- (Implementation lives in runSchedulers via coroutines to keep heartbeat light.)
function CreatureSpawner:_octopusLoop()
end

-- Entry that starts lightweight scheduler coroutines.
function CreatureSpawner:runSchedulers()
	task.spawn(self.spawnPiratesScheduler, self)
	task.spawn(self.spawnCrabScheduler, self)
	task.spawn(self.spawnOctopusScheduler, self)
end

function CreatureSpawner:spawnPiratesScheduler()
	-- static shoreline patrols
	for i = 1, GameConfig.Creatures.Pirate.Count do
		local clone = self._models.Pirate:Clone()
		clone.Parent = Workspace
	end
end

function CreatureSpawner:spawnCrabScheduler()
	local cfg = GameConfig.Creatures.Crab
	while true do
		task.wait(cfg.SpawnEvery)
		GameServer:getSpawnHandler()(self)
	end
end

function CreatureSpawner:spawnOctopusScheduler()
	local cfg = GameConfig.Creatures.Octopus
	while true do
		task.wait(cfg.SpawnEvery)
		GameServer:getOceanHandler()(self)
	end
end

-- Crab erupt from a sand hole ahead of the leading player.
function CreatureSpawner:eruptCrab()
	local zone = GameServer:chooseSandHoleZone()
	if not zone then
		return
	end
	local z = zone.minZ + math.random() * (zone.maxZ - zone.minZ)
	local x = zone.x + math.random(-2, 2) * 0.5
	for _ = 1, GameConfig.Creatures.Crab.HolesPerWave do
		local clone = self._models.Crab:Clone()
		clone.PrimaryPart.CFrame = CFrame.new(x, 1.5, z)
		clone.Parent = Workspace
		task.defer(GameServer:activateCrab(), clone)
		z = z + 3
	end
end

return CreatureSpawner
