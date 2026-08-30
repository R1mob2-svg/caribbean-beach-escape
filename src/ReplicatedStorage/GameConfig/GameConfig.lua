--!strict
-- GameConfig: shared, single source of truth for the Caribbean Beach Escape game.
-- Read-only references are shared with clients via ReplicatedStorage.

local GameConfig = {
	GameName = "Caribbean Beach Escape",

	-- ==== WORLD ===================================================================
	-- The escape run happens along the Z axis. Spawn is at z = 0,
	-- the escape boat sits at z = BeachLength.
	BeachLength = 400,
	BeachWidth = 24,
	BeachCenterZ = 0,           -- start line
	BoatZ = 400,                -- finish line

	-- ==== CORE LOOP ===============================================================
	-- Time (seconds) to "escape" to win with zero waiting once the run starts.
	VictoryZ = 400,

	-- ==== MOVEMENT ================================================================
	RunSpeed = 22,
	WalkSpeed = 16,
	JumpPower = 50,
	BaseHealth = 100,
	DamageFromHit = 34,

	-- ==== CHECKPOINTS =============================================================
	-- Z positions where checkpoints (palm flags) live. Reaching one re-spawns
	-- the player there on death instead of the start.
	CheckpointPositions = { 100, 200, 300 },
	CheckpointRespawnY = 3,
	CheckpointSafeRadius = 4,

	-- ==== CREATURES (server spawns these) =======================================
	Creatures = {
		Crab = {
			ModelName = "KillerCrab",
			SpawnEvery = 6.0,         -- seconds between crab spawn attempts
			HolesPerWave = 2,          -- sand holes that pop simultaneously
			Speed = 16,
			Damage = 34,
			AggroRange = 24,
			HoleLife = 5.0,            -- how long a sand hole is dangerous
			LungeSpeed = 34,
		},
		Octopus = {
			ModelName = "OceanOctopus",
			SpawnEvery = 8.0,
			CountPerWave = 2,
			Speed = 12,
			Damage = 30,
			TargetShoreX = 8,          -- how far inland waves reach
			WavePause = 1.5,
		},
		Pirate = {
			ModelName = "PiratePatrol",
			Count = 4,                 -- patrol along the shoreline
			Speed = 10,
			Damage = 34,
			PatrolRadius = 10,
			VisionRange = 20,
			AttackCooldown = 1.0,
		},
	},

	-- ==== HAZARD ZONES ============================================================
	-- Sand holes (crab spawners) live on the landward half of the beach.
	SandHoleZones = {
		{ minZ = 40,  maxZ = 90,  x = -6, count = 3 },
		{ minZ = 120, maxZ = 170, x = -4, count = 3 },
		{ minZ = 210, maxZ = 260, x = -5, count = 3 },
		{ minZ = 310, maxZ = 355, x = -6, count = 2 },
	},

	-- ==== UI ======================================================================
	Ui = {
		IntroTitle = "Caribbean Beach Escape",
		IntroBody = "Killer crabs burst from the sand! Octopuses slither from the surf! Swashbuckling pirates patrol the shore!\n\nSprint down the beach, dodge everything, and reach the escape boat at the far end!",
		HintText = "Run forward! Reach the orange boat to escape. Grab the palm flags - they are your checkpoints!",
		WinText = "YOU ESCAPED!",
		DeathText = "A creature got you! Respawning at checkpoint...",
	},

	-- ==== SAFETY ==================================================================
	-- Required for the escape to always be funnable: keeps hazard spread behind
	-- the player's checkpoint zone so the run stays fair.
	MinSafeZ = 25,
}

return GameConfig
