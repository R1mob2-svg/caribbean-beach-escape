--!strict
-- EnvironmentBuilder: builds the Caribbean tropical coastline visuals and terrain.
-- Uses Roblox Terrain plus pure-part props (no ripped assets) for a colourful,
-- clearly readable beach run.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Terrain = Workspace.Terrain
local Lighting = game:GetService("Lighting")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local EnvironmentBuilder = {}

local BOCA_DEEP = Color3.fromRGB(18, 96, 145)
local BOCA_MID = Color3.fromRGB(40, 150, 190)
local SAND = Color3.fromRGB(240, 211, 155)
local GRASS = Color3.fromRGB(112, 178, 94)
local PALM_GREEN = Color3.fromRGB(70, 130, 50)

local function newPart(name: string, props: { any }): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	if props.Material then
		part.Material = props.Material
		props.Material = nil
	end
	for key, value in pairs(props) do
		part[key] = value
	end
	part.Parent = Workspace
	return part
end

function EnvironmentBuilder.build()
	-- Daylight tropical vibe.
	Lighting.ClockTime = 14
	Lighting.GeographicLatitude = 18
	Lighting.Brightness = 3

	local beachLength = GameConfig.BeachLength
	local beachWidth = GameConfig.BeachWidth

	-- --- Ocean column (left of the beach, x negative) ---------------------------
	Terrain:FillBlock(CFrame.new(-60, -2, beachLength / 2),
		Vector3.new(180, 40, beachLength + 80),
		Enum.Material.Water)
	Terrain:FillBlock(CFrame.new(-60, -40, beachLength / 2),
		Vector3.new(180, 20, beachLength + 80),
		Enum.Material.Sand)

	-- --- Beach sand (walkable strip) ---------------------------------------------
	Terrain:FillBlock(CFrame.new(0, 0, beachLength / 2),
		Vector3.new(beachWidth, 6, beachLength),
		Enum.Material.Sand)
	Terrain:FillBlock(CFrame.new(0, -5, beachLength / 2),
		Vector3.new(beachWidth, 6, beachLength),
		Enum.Material.Ground)

	-- --- Jungle treeline (right of the beach, x positive) ------------------------
	Terrain:FillBlock(CFrame.new(beachWidth + 40, 0, beachLength / 2),
		Vector3.new(220, 8, beachLength + 80),
		Enum.Material.Grass)

	-- --- Escape boat at the far end (z = BeachLength) ----------------------------
	local boat = Instance.new("Model")
	boat.Name = "EscapeBoat"
	local hull = newPart("Hull", {
		Size = Vector3.new(5, 2, 10),
		Position = Vector3.new(0, 0.5, beachLength + 6),
		Color = Color3.fromRGB(230, 120, 40),
		Material = Enum.Material.Wood,
	})
	hull.Parent = boat
	local bow = newPart("Bow", {
		Shape = Enum.PartType.Wedge,
		Size = Vector3.new(5, 2, 4),
		CFrame = CFrame.new(0, 0.5, beachLength + 13) * CFrame.Angles(0, math.rad(180), 0),
		Color = Color3.fromRGB(230, 120, 40),
		Material = Enum.Material.Wood,
	})
	bow.Parent = boat
	boat.PrimaryPart = hull
	boat.Parent = Workspace

	-- --- Sand holes (visible danger markers on the landward half) ----------------
	for _, zone in ipairs(GameConfig.SandHoleZones) do
		for i = 1, zone.count do
			local z = zone.minZ + ((zone.maxZ - zone.minZ) * (i - 1)) / math.max(1, zone.count - 1)
			local n = math.random(-1, 1)
			local x = zone.x + n * 1.5
			local hole = newPart("SandHole", {
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(3, 0.4, 3),
				CFrame = CFrame.new(x, 0.2, z),
				Color = Color3.fromRGB(90, 60, 35),
				Material = Enum.Material.Sand,
				Transparency = 0.0,
			})
			local rim = newPart("SandHoleRim", {
				Size = Vector3.new(4, 0.2, 4),
				CFrame = CFrame.new(x, 0.1, z),
				Color = Color3.fromRGB(210, 175, 120),
				Material = Enum.Material.Sand,
				Transparency = 0.55,
			})
			rim.Parent = hole
			propsTag(hole, "SandHole")
		end
	end

	-- --- Checkpoint palm flags ---------------------------------------------------
	for i, z in ipairs(GameConfig.CheckpointPositions) do
		local cp = Instance.new("Model")
		cp.Name = "Checkpoint_" .. tostring(i)
		local pole = newPart("Pole", {
			Size = Vector3.new(0.4, 5, 0.4),
			Position = Vector3.new(9, 2.5, z),
			Color = Color3.fromRGB(130, 95, 40),
			Material = Enum.Material.Wood,
		})
		pole.Parent = cp
		local flag = newPart("Flag", {
			Size = Vector3.new(2, 1.2, 0.2),
			CFrame = CFrame.new(10.2, 5.2, z),
			Color = Color3.fromRGB(255, 170, 0),
			Material = Enum.Material.Fabric,
		})
		flag.Parent = cp
		cp.PrimaryPart = pole
		cp.Parent = Workspace
	end

	-- --- Ambient life: a few static decorative palms (non-hazard) ----------------
	decoratePalms(beachLength)
end

function EnvironmentBuilder.buildStartPlatform()
	-- Simple spawn platform just before the beach start.
	newPart("SpawnPad", {
		Size = Vector3.new(14, 1, 6),
		Position = Vector3.new(0, -1.5, -6),
		Color = Color3.fromRGB(170, 120, 55),
		Material = Enum.Material.Wood,
	})
end

local function decoratePalms(beachLength: number)
	-- Palms along the treeline edge, clearly non-interactive decoration.
	for z = 10, beachLength - 10, 55 do
		local palm = Instance.new("Model")
		local trunk = newPart("Trunk", {
			Size = Vector3.new(1, 4, 1),
			CFrame = CFrame.new(11, 2, z) * CFrame.Angles(0, 0, math.rad(6)),
			Color = Color3.fromRGB(95, 70, 35),
			Material = Enum.Material.Wood,
		})
		trunk.Parent = palm
		local leaves1 = newPart("Leaves", {
			Size = Vector3.new(5, 0.4, 4),
			CFrame = CFrame.new(11.5, 4.2, z) * CFrame.Angles(math.rad(20), 0, 0),
			Color = PALM_GREEN,
			Material = Enum.Material.Foliage,
		})
		leaves1.Parent = palm
		palm.Parent = Workspace
	end
end

function propsTag(part: Part, tag: string)
	local value = Instance.new("StringValue")
	value.Name = "GmxTag"
	value.Value = tag
	value.Parent = part
end

return EnvironmentBuilder
