-- Knit Packages
local MarketplaceService = game:GetService("MarketplaceService")
local PathfindingService = game:GetService("PathfindingService")
local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

-- Services
local Players = game:GetService("Players")
local DataService

local HomePlayerService = Knit.CreateService({
	Name = "HomePlayerService",
	Client = {
		CharacterAdded = Knit.CreateSignal(),
		HomeUpdated = Knit.CreateSignal(),
	},
	Homes = {},
})

--|| Client Functions ||--
function HomePlayerService.Client:LockHome(player: Player)
	HomePlayerService:LockHome(player)
end

function HomePlayerService.Client:TestEvent(player: Player): boolean
	return false
end
-- ||  Server Functions ||--
function HomePlayerService:SetupHome()
	local slots = workspace:WaitForChild("Slots")
	for _, slot in pairs(slots:GetChildren()) do
		local platforms = {}
		local index = 0
		local target = nil
		local dor = nil
		local lock = nil
		for _, platform in pairs(slot:GetChildren()) do
			if platform.Name == "platform" then
				index += 1
				table.insert(platforms, {
					platform = platform,
					id = platform.Name .. index,
					status = false,
					money = platform:FindFirstChild("money"),
					brainrot = nil,
				})
			end
			if platform.Name == "target" then
				target = platform
			end
			if platform.Name == "pintu" then
				dor = platform
			end
			if platform.Name == "lock" then
				lock = platform
			end
		end
		dor.CanCollide = false
		dor.Transparency = 1
		self.Homes[slot.Name] = {
			object = slot,
			id = slot.Name,
			status = false,
			player = nil,
			platforms = platforms,
			target = target,
			dor = dor,
			islock = false,
			lock = lock,
		}
	end
end
function HomePlayerService:LockHome(player)
	local home = self:GetPlayerHome(player)
	if not home then
		return
	end
	home.islock = true
	home.dor.CanCollide = true
	home.dor.Transparency = 0.6
	self.Client.HomeUpdated:FireAll(self.Homes)
	task.delay(10, function()
		self:UnlockHome(player)
	end)
end
function HomePlayerService:UnlockHome(player)
	local home = self:GetPlayerHome(player)
	if not home then
		return
	end
	home.islock = false
	home.dor.CanCollide = false
	home.dor.Transparency = 1
	self.Client.HomeUpdated:FireAll(self.Homes)
end
function HomePlayerService:GetEmptyHome()
	for _, home in pairs(self.Homes) do
		if not home.status then
			return home
		end
	end
	return nil
end
function HomePlayerService:GetPlayerHome(player)
	for _, home in pairs(self.Homes) do
		if home.player == player then
			return home
		end
	end
	return nil
end
function HomePlayerService:GetEmptyPlatform(home)
	for _, platform in pairs(home.platforms) do
		if not platform.status then
			return platform
		end
	end
	return nil
end
function HomePlayerService:MoveToPlatform(player, brainrot)
	local home = self:GetPlayerHome(player)
	if not home then
		return nil
	end
	local platform = self:GetEmptyPlatform(home)
	if not platform then
		return nil
	end
	platform.status = true
	platform.brainrot = brainrot
	brainrot.object:PivotTo(platform.platform.CFrame)
	brainrot.object.HumanoidRootPart.Anchored = true
end

-- KNIT START
function HomePlayerService:KnitStart()
	local function playerAdded(player: Player)
		player.CharacterAdded:Connect(function(character)
			local home = self:GetEmptyHome()
			if not home then
				return
			end
			home.status = true
			home.player = player

			task.defer(function()
				local targetWorld = home.target.CFrame
				player.Character.HumanoidRootPart.CFrame = targetWorld
			end)
			self.Client.CharacterAdded:FireAll(self.Homes)
		end)

		-- code playeradded
	end

	Players.PlayerAdded:Connect(playerAdded)
	for _, player in pairs(Players:GetChildren()) do
		playerAdded(player)
	end

	print("TemplateService Started")
	-- KNIT END
end

function HomePlayerService:KnitInit()
	self:SetupHome()
end

return HomePlayerService
