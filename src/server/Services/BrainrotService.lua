-- Knit Packages
local MarketplaceService = game:GetService("MarketplaceService")
local PathfindingService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")
local PhysicsService = game:GetService("PhysicsService")
local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

-- Services
local Players = game:GetService("Players")
local HomePlayerService

local BrainrotService = Knit.CreateService({
	Name = "BrainrotService",
	Client = {
		BrainRootMoving = Knit.CreateSignal(),
		OnDefaultPathGenrated = Knit.CreateSignal(),
		BrainRootAdded = Knit.CreateSignal(),
		BrainRootRemoved = Knit.CreateSignal(),
	},
	BrainRoots = {},
	ReachedConnections = {},
	PlayerBrainRoots = {},
})
local testingNPC = workspace.TestingNPC
local start_part = workspace:WaitForChild("Start")
local end_part = workspace:WaitForChild("End")

-- Variable
local path = PathfindingService:CreatePath()

local TEST_DESTINATION = Vector3.new(100, 0, 100)

local waypoints
local nextWaypointIndex
local reachedConnection
local blockedConnection

local defaultWayPoints = {}

--|| Client Functions ||--
function BrainrotService.Client:ChangeWaypoint(player: Player, id)
	BrainrotService:ChangeWaypoint(player, id)
end

function BrainrotService.Client:TestEvent(player: Player): boolean
	return false
end

--|| Server Functions ||--
function BrainrotService:ChangeWaypoint(player, id)
	local target_pos = HomePlayerService:GetPlayerHome(player).target.Position
	local brainrot = self.BrainRoots[id]
	if not brainrot then
		return
	end

	local success, _error = pcall(function()
		path:ComputeAsync(brainrot.object.HumanoidRootPart.Position, target_pos)
	end)

	if success and path.Status == Enum.PathStatus.Success then
		local newWayPoints = path:GetWaypoints()
		self.PlayerBrainRoots[player] = self.BrainRoots[id]
		self.BrainRoots[id] = nil
		-- remove brainrot to in client
		self.Client.BrainRootRemoved:FireAll(id)
		self:Moving(self.PlayerBrainRoots[player], newWayPoints, true, player)
	end
end

function BrainrotService:GenerateDefaultWay()
	local success, _error = pcall(function()
		path:ComputeAsync(start_part.Position, end_part.Position)
	end)
	if success and path.Status == Enum.PathStatus.Success then
		defaultWayPoints = path:GetWaypoints()
		self.Client.OnDefaultPathGenrated:FireAll(defaultWayPoints)
	end
end
function BrainrotService:ChangeToPlayer(id, player) end
function BrainrotService:Destroy(id)
	local brainrot = self.BrainRoots[id]
	brainrot.object:Destroy()
	self.BrainRoots[id] = nil
	self.Client.BrainRootRemoved:FireAll(id)
end
function BrainrotService:SpawnBrainrot()
	local id = tostring(os.time())
	local npc = testingNPC:clone()
	BrainrotService:SetupBrainrot(npc, "Brainrot")
	npc.Parent = workspace
	npc:PivotTo(start_part.CFrame)

	local brainrot = {
		id = id,
		object = npc,
		path_index = 1,
	}
	self.BrainRoots[id] = brainrot
	self:Moving(brainrot, defaultWayPoints)

	self.Client.BrainRootAdded:FireAll(id, brainrot)
end
function BrainrotService:Spawner()
	task.spawn(function()
		while true do
			task.wait(5)
			self:SpawnBrainrot()
		end
	end)
end

function BrainrotService:Moving(brainrot, waypoints, isToPlayer: boolean, player: Player | nil)
	player = player or nil
	isToPlayer = isToPlayer or false
	if #waypoints <= 1 then
		print("waypoint count is less than 1")
		return
	end

	local id = brainrot.id
	local character = brainrot.object

	local humanoid = character:WaitForChild("Humanoid")
	humanoid.WalkSpeed = 10

	if self.ReachedConnections[id] then
		self.ReachedConnections[id]:Disconnect()
		self.ReachedConnections[id] = nil
	end

	if not self.ReachedConnections[id] then
		self.ReachedConnections[id] = humanoid.MoveToFinished:Connect(function(reached)
			if brainrot.path_index < #waypoints then
				brainrot.path_index += 1
				humanoid:MoveTo(waypoints[brainrot.path_index].Position)
			else
				self.ReachedConnections[id]:Disconnect()
				self.ReachedConnections[id] = nil
				if isToPlayer then
					-- change position to the plafrom player base
					HomePlayerService:MoveToPlatform(player, brainrot)
				else
					self:Destroy(id)
				end
			end
		end)
	end

	brainrot.path_index = 2
	humanoid:MoveTo(waypoints[brainrot.path_index].Position)
	self.Client.BrainRootMoving:FireAll(character)
end
function BrainrotService:SetupBrainrot(model: Model, group: string)
	for i, v in ipairs(model:GetDescendants()) do
		if not v:IsA("BasePart") then
			continue
		end
		v.CollisionGroup = group
	end
end

-- KNIT START
function BrainrotService:KnitStart()
	HomePlayerService = Knit.GetService("HomePlayerService")
	BrainrotService:GenerateDefaultWay()
	BrainrotService:Spawner()

	local function playerAdded(player: Player)
		player.CharacterAdded:Connect(function(character)
			task.defer(function()
				BrainrotService:SetupBrainrot(character, "Player")
			end)
		end)

		-- code playeradded
	end

	Players.PlayerAdded:Connect(playerAdded)
	for _, player in pairs(Players:GetChildren()) do
		playerAdded(player)
	end

	print("BrainrotService Started")
	-- KNIT END
end
function BrainrotService:KnitInit()
	PhysicsService:RegisterCollisionGroup("Brainrot")
	PhysicsService:RegisterCollisionGroup("Player")
	PhysicsService:CollisionGroupSetCollidable("Brainrot", "Player", false)
	PhysicsService:CollisionGroupSetCollidable("Brainrot", "Brainrot", false)
	PhysicsService:CollisionGroupSetCollidable("Player", "Default", true)
end

return BrainrotService
