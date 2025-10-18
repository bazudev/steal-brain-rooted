-- Knit Packages
local MarketplaceService = game:GetService("MarketplaceService")
local PathfindingService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")
local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

-- Services
local Players = game:GetService("Players")
local DataService

local BrainrotService = Knit.CreateService({
	Name = "BrainrotService",
	Client = {
		BrainRootMoving = Knit.CreateSignal(),
		OnDefaultPathGenrated = Knit.CreateSignal(),
	},
	BrainRoots = {},
	ReachedConnections = {},
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

function BrainrotService.Client:TestEvent(player: Player): boolean
	return false
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
function BrainrotService:Destroy(id)
	local brainrot = self.BrainRoots[id]
	brainrot.object:Destroy()
	self.BrainRoots[id] = nil
end
function BrainrotService:SpawnBrainrot()
	local id = tostring(os.time())
	local npc = testingNPC:clone()
	npc.Parent = workspace
	npc:PivotTo(start_part.CFrame)

	local brainrot = {
		id = id,
		object = npc,
		path_index = 1,
	}
	self.BrainRoots[id] = brainrot
	self:Moving(brainrot, defaultWayPoints)
end
function BrainrotService:Spawner()
	task.spawn(function()
		while true do
			task.wait(5)
			self:SpawnBrainrot()
		end
	end)
end

function BrainrotService:Moving(brainrot, waypoints)
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
			if self.BrainRoots[id].path_index < #waypoints then
				self.BrainRoots[id].path_index += 1
				humanoid:MoveTo(waypoints[self.BrainRoots[id].path_index].Position)
			else
				self.ReachedConnections[id]:Disconnect()
				self.ReachedConnections[id] = nil
				self:Destroy(id)
			end
		end)
	end

	self.BrainRoots[id].path_index = 2
	humanoid:MoveTo(waypoints[self.BrainRoots[id].path_index].Position)
	self.Client.BrainRootMoving:FireAll(character)
end

-- KNIT START
function BrainrotService:KnitStart()
	BrainrotService:GenerateDefaultWay()
	BrainrotService:Spawner()

	local function characterAdded(player: Player, character: Instance) end

	local function playerAdded(player: Player)
		player.CharacterAdded:Connect(function(character)
			characterAdded(player, character)
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

return BrainrotService
