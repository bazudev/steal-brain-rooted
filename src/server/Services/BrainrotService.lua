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
		PlayAnimation = Knit.CreateSignal(),
		StopAnimation = Knit.CreateSignal(),
	},
	BrainRoots = {},
	ReachedConnections = {},
	PlayerBrainRoots = {},
	PlayerGrabbedBrainRoots = {},
})
local testingNPC = workspace.TestingNPC
local start_part = workspace:WaitForChild("Start")
local end_part = workspace:WaitForChild("End")

-- Variable
local path = PathfindingService:CreatePath()

local TEST_DESTINATION = Vector3.new(100, 0, 100)

local defaultWayPoints = {}

--|| Client Functions ||--
function BrainrotService.Client:ChangeWaypoint(player: Player, id)
	BrainrotService:ChangeWaypoint(player, id)
end
function BrainrotService.Client:AttatchToPlayer(player: Player, platformCframe, brainrotId)
	BrainrotService:AttatchToPlayer(player, platformCframe, brainrotId)
end
function BrainrotService.Client:DetatchFromPlayer(player: Player)
	BrainrotService:DetatchFromPlayer(player)
end
function BrainrotService.Client:MoveToPlatform(player: Players, platformId)
	BrainrotService:MoveToPlatform(player, platformId)
end

function BrainrotService.Client:TestEvent(player: Player): boolean
	return false
end

--|| Server Functions ||--
function BrainrotService:MoveToPlatform(player: Players, platformId)
	local playerGrabBrainroot = self.PlayerGrabbedBrainRoots[player]
	if not playerGrabBrainroot then
		return
	end
	print("platform id :", platformId)
	BrainrotService:RemoveWeld(player)
	HomePlayerService:MoveToPlatformById(player, platformId, playerGrabBrainroot.brainrot)
	-- playerGrabBrainroot.brainrot.object.HumanoidRootPart.CFrame = playerGrabBrainroot.oldCframe
	BrainrotService:SetupBrainrot(playerGrabBrainroot.brainrot.object, "Brainrot")

	self.PlayerBrainRoots[player] = {
		player = player,
		brainrot = playerGrabBrainroot.brainrot,
	}

	self.PlayerGrabbedBrainRoots[player] = nil
	self.Client.StopAnimation:Fire(player, player.Character)
end

function BrainrotService:AttatchToPlayer(player: Players, platformId, brainrotId)
	local playerBrainrot = BrainrotService:FindPlayerBrainrot(brainrotId)
	if not playerBrainrot then
		return
	end

	local character = player.Character
	if not character then
		print("charater not found")
		return
	end
	local playerGrabBrainroot = {
		oldPlayer = playerBrainrot.player,
		brainrot = playerBrainrot.brainrot,
		platformId = platformId,
		oldCframe = nil,
	}
	self.PlayerBrainRoots[playerGrabBrainroot.oldPlayer] = nil

	local npc = playerGrabBrainroot.brainrot.object
	BrainrotService:SetupBrainrot(npc, "Grabbed")
	npc.Parent = workspace

	-- setPlayer to playerGrabBrainroot
	playerGrabBrainroot.oldCframe = npc.HumanoidRootPart.CFrame
	self.PlayerGrabbedBrainRoots[player] = playerGrabBrainroot

	local hand = character:WaitForChild("RightHand")
	local rotation = CFrame.Angles(math.rad(-90), 0, 0)
	npc.HumanoidRootPart.CFrame = hand.CFrame * CFrame.new(0, -1, 0) * rotation
	local weld = Instance.new("Motor6D")
	weld.Name = "righthandweld"
	weld.Part0 = hand
	weld.Part1 = npc.HumanoidRootPart
	weld.C0 = CFrame.new(0, -1, 0) * rotation
	weld.C1 = CFrame.new(0, 0, 0)
	weld.Parent = hand
	npc.HumanoidRootPart.Anchored = false
	self.Client.PlayAnimation:Fire(player, character, "toolnone", "ToolNoneAnim")
end
function BrainrotService:DetatchFromPlayer(player)
	local playerGrabBrainroot = self.PlayerGrabbedBrainRoots[player]
	if not playerGrabBrainroot then
		return
	end

	BrainrotService:RemoveWeld(player)
	HomePlayerService:MoveToPlatformById(
		playerGrabBrainroot.oldPlayer,
		playerGrabBrainroot.platformId,
		playerGrabBrainroot.brainrot
	)

	playerGrabBrainroot.brainrot.object.HumanoidRootPart.CFrame = playerGrabBrainroot.oldCframe
	BrainrotService:SetupBrainrot(playerGrabBrainroot.brainrot.object, "Brainrot")

	self.PlayerBrainRoots[playerGrabBrainroot.oldPlayer] = {
		player = playerGrabBrainroot.oldPlayer,
		brainrot = playerGrabBrainroot.brainrot,
	}

	self.PlayerGrabbedBrainRoots[player] = nil
	self.Client.StopAnimation:Fire(player, player.Character)
end
function BrainrotService:RemoveWeld(player: Player)
	local character = player.Character
	local hand = character:FindFirstChild("RightHand")

	for _, obj in pairs(hand:GetChildren()) do
		if obj:IsA("Motor6D") and obj.Name == "righthandweld" then
			print("detory motor6d")
			obj:Destroy()
		end
	end
end
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
		self.PlayerBrainRoots[player] = {
			player = player,
			brainrot = self.BrainRoots[id],
		}
		self.BrainRoots[id] = nil
		-- remove brainrot to in client
		self.Client.BrainRootRemoved:FireAll(id)
		self:Moving(self.PlayerBrainRoots[player].brainrot, newWayPoints, true, player)
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
function BrainrotService:FindPlayerBrainrot(brainrotId)
	for _, data in pairs(self.PlayerBrainRoots) do
		if data.brainrot.id == brainrotId then
			return data
		end
	end

	return nil
end
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
		if group == "Grabbed" then
			v.Massless = true
		else
			v.Massless = false
		end
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
	PhysicsService:RegisterCollisionGroup("Grabbed")

	PhysicsService:CollisionGroupSetCollidable("Grabbed", "Default", false)
	PhysicsService:CollisionGroupSetCollidable("Grabbed", "Grabbed", false)
	PhysicsService:CollisionGroupSetCollidable("Grabbed", "Player", false)

	PhysicsService:CollisionGroupSetCollidable("Brainrot", "Player", false)
	PhysicsService:CollisionGroupSetCollidable("Brainrot", "Brainrot", false)

	PhysicsService:CollisionGroupSetCollidable("Player", "Default", true)
end

return BrainrotService
