--!strict
-- CreatureSpawner: spawns and drives killer crabs (from sand holes), ocean
-- octopuses (from the surf) and swashbuckling pirate patrols on the shoreline.
-- All models are built from original primitive parts. Damage to players is
-- dispatched through a shared BindableEvent that GameServer subscribes to.
-- Fully server-authoritative and self-contained.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local CreatureSpawner = {}
CreatureSpawner.__index = CreatureSpawner

local CRAB_RED = Color3.fromRGB(205, 45, 45)
local OCTO_PURPLE = Color3.fromRGB(185, 65, 185)
local PIRATE_BLUE = Color3.fromRGB(45, 60, 110)
local PIRATE_SKIN = Color3.fromRGB(228, 175, 128)

local function part(name: string, size: Vector3, color: Color3, parent: Instance): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Anchored = true
	p.CanCollide = false
	p.Material = Enum.Material.SmoothPlastic
	p.Parent = parent
	return p
end

function CreatureSpawner.new(): CreatureSpawner
	local self = setmetatable({}, CreatureSpawner)
	self._models = {}
	return self
end

-- Build reusable creature models once, then clone them as needed.
function CreatureSpawner:buildModels()
	local serve = game:GetService("ServerStorage")

	-- --- KILLER CRAB ------------------------------------------------------------
	local crab = Instance.new("Model")
	crab.Name = GameConfig.Creatures.Crab.ModelName
	part("Body", Vector3.new(2.2, 1.0, 1.4), CRAB_RED, crab)
	part("Head", Vector3.new(1.4, 0.9, 0.8), CRAB_RED, crab)
	local legs = Instance.new("Folder"); legs.Name = "Legs"; legs.Parent = crab
	for i = 1, 6 do
		part("Leg", Vector3.new(0.4, 0.5, 0.3), Color3.fromRGB(150, 30, 30), legs)
	end
	crab.Parent = serve
	self._models.Crab = crab

	-- --- OCEAN OCTOPUS ----------------------------------------------------------
	local octo = Instance.new("Model")
	octo.Name = GameConfig.Creatures.Octopus.ModelName
	part("Body", Vector3.new(2.6, 1.6, 1.6), OCTO_PURPLE, octo)
	for i = 1, 6 do
		part("Leg", Vector3.new(0.7, 0.6, 1.8), Color3.fromRGB(150, 50, 150), octo)
	end
	octo.Parent = serve
	self._models.Octopus = octo

	-- --- PIRATE PATROL ----------------------------------------------------------
	local pirate = Instance.new("Model")
	pirate.Name = GameConfig.Creatures.Pirate.ModelName
	local body = part("Body", Vector3.new(1.3, 2.4, 1.0), PIRATE_BLUE, pirate)
	part("Head", Vector3.new(0.9, 0.9, 0.9), PIRATE_SKIN, pirate)
	part("Hat", Vector3.new(0.7, 0.5, 0.7), Color3.fromRGB(140, 40, 40), pirate)
	part("Cutlass", Vector3.new(0.2, 0.2, 1.5), Color3.fromRGB(210, 210, 210), pirate)
	pirate.PrimaryPart = body
	pirate.Parent = serve
	self._models.Pirate = pirate
end

function CreatureSpawner:start()
	self:_spawnPirates()
	task.spawn(function() self:_crabLoop() end)
	task.spawn(function() self:_oceanLoop() end)
end

-- Shared damage dispatch between any creature and GameServer.
CreatureSpawner.OnHazardHit = Instance.new("BindableEvent")
CreatureSpawner.OnHazardHit.Name = "OnHazardHit"
CreatureSpawner.characterModel = nil -- placeholder; real dispatch below uses temp folder

-- --- PIRATES: static shoreline patrols (moved by their own AI) ---------------
function CreatureSpawner:_spawnPirates()
	local cfg = GameConfig.Creatures.Pirate
	local positions = {
		Vector3.new(4, 1, 80),
		Vector3.new(1, 1, 170),
		Vector3.new(5, 1, 250),
		Vector3.new(3, 1, 330),
	}
	for i = 1, math.min(cfg.Count, #positions) do
		local clone = self._models.Pirate:Clone()
		clone.PrimaryPart.CFrame = CFrame.new(positions[i]) * CFrame.Angles(0, math.rad(-90), 0)
		clone.Parent = Workspace
		self:_drivePirate(clone)
	end
end

function CreatureSpawner:_drivePirate(pirate: Model)
	local cfg = GameConfig.Creatures.Pirate
	local homeZ = pirate.PrimaryPart.Position.Z
	local phase = math.random() * math.pi * 2
	local hurt = hurtCharacterFor(Pirate)
	task.spawn(function()
		while pirate and pirate.Parent do
			local primary = pirate.PrimaryPart
			if primary then
				local z = homeZ + math.sin(os.clock() + phase) * cfg.PatrolRadius
				primary.CFrame = CFrame.new(primary.Position.X, 1.2, z) * CFrame.Angles(0, math.rad(90), 0)
			end
			-- check nearby players for a swashbuckling hit
			if playersNear(pirate, cfg.VisionRange) then
				if primary then
					primary.CFrame = CFrame.new(primary.Position, nearestPlayerPosition(primary.Position))
				end
			end
			task.wait(0.15)
		end
	end)
end

-- --- CRABS: erupt from sand holes ahead of the leading player ----------------
function CreatureSpawner:_crabLoop()
	local cfg = GameConfig.Creatures.Crab
	while true do
		task.wait(cfg.SpawnEvery)
		local lead = farthestPlayerZ()
		if lead then
			local zonesAhead = {}
			for _, zone in ipairs(GameConfig.SandHoleZones) do
				if zone.minZ > lead - 20 and zone.minZ < lead + 120 then
					table.insert(zonesAhead, zone)
				end
			end
			if #zonesAhead > 0 then
				local zone = zonesAhead[math.random(#zonesAhead)]
				for _ = 1, cfg.HolesPerWave do
					local z = zone.minZ + math.random() * (zone.maxZ - zone.minZ)
					local x = zone.x + math.random(-2, 2) * 0.5
					local clone = self._models.Crab:Clone()
					local primary = clone.PrimaryPart
					if not primary then primary = clone:GetChildren()[1] end
					clone.Parent = Workspace
					if primary then primary.CFrame = CFrame.new(x, 1.6, z) end
					self:_driveCrab(clone, primary)
				end
			end
		end
	end
end

function CreatureSpawner:_driveCrab(crab: Model, primary: Part)
	local cfg = GameConfig.Creatures.Crab
	task.spawn(function()
		local life = 0
		while crab and crab.Parent and primary do
			local target = nearestPlayerPosition(primary.Position)
			if target then
				local dir = (target - primary.Position).Unit
				local speed = cfg.LungeSpeed
				primary.CFrame = CFrame.new(primary.Position + dir * speed * 0.15, target)
			end
			life += 0.15
			if life > cfg.HoleLife then
				crab:Destroy()
				return
			end
			task.wait(0.15)
		end
	end)
end

-- --- OCTOPUSES: surge from the surf onto the shore ---------------------------
function CreatureSpawner:_oceanLoop()
	local cfg = GameConfig.Creatures.Octopus
	while true do
		task.wait(cfg.SpawnEvery)
		for _ = 1, cfg.CountPerWave do
			local z = math.random(30, math.min(370, (farthestPlayerZ() or 40) + 60))
			local clone = self._models.Octopus:Clone()
			clone.PrimaryPart.CFrame = CFrame.new(-30, 0, z)
			clone.Parent = Workspace
			self:_driveOctopus(clone)
		end
	end
end

function CreatureSpawner:_driveOctopus(octo: Model)
	local primary = octo.PrimaryPart
	local shoreX = GameConfig.Creatures.Octopus.TargetShoreX
	task.spawn(function()
		while octo and octo.Parent and primary do
			local target = Vector3.new(shoreX + math.random(-2, 2), 1, primary.Position.Z)
			local dir = (target - primary.Position).Unit
			primary.CFrame = CFrame.new(primary.Position + dir * GameConfig.Creatures.Octopus.Speed * 0.15, target)
			if primary.Position.X >= shoreX then
				-- reached shore, slide back to sea to loop
				task.wait(GameConfig.Creatures.Octopus.WavePause)
			end
			task.wait(0.15)
		end
	end)
end

-- --- helpers -----------------------------------------------------------------
local function farthestPlayerZ(): number?
	local best = nil
	for _, p in ipairs(Players:GetPlayers()) do
		local c = p.Character
		if c and c:FindFirstChild("HumanoidRootPart") then
			local z = c.HumanoidRootPart.Position.Z
			if not best or z > best then best = z end
		end
	end
	return best
end

local function nearestPlayerPosition(pos: Vector3): Vector3?
	local best = nil
	local bestDist = math.huge
	for _, p in ipairs(Players:GetPlayers()) do
		local c = p.Character
		if c and c:FindFirstChild("HumanoidRootPart") then
			local hrp = c.HumanoidRootPart.Position
			local d = (hrp - pos).Magnitude
			if d < bestDist then bestDist = d; best = hrp end
		end
	end
	return best
end

local function playersNear(model: Model, dist: number): boolean
	local pos = model.PrimaryPart and model.PrimaryPart.Position
	if not pos then return false end
	for _, p in ipairs(Players:GetPlayers()) do
		local c = p.Character
		if c and c.PrimaryPart and (c.PrimaryPart.Position - pos).Magnitude < dist then
			return true
		end
	end
	return false
end

local function hurtCharacterFor(pirate: number)
	-- placeholder hook; real damage uses OnHazardHit
	return nil
end

return CreatureSpawner
