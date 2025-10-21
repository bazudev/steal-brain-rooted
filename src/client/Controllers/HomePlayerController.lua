-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- Knit packages
local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)

-- Player
local player = Players.LocalPlayer

-- Services
local HomePlayerService
local BrainrotService

-- Controller
local ToolsController

-- TemplateController
local HomePlayerController = Knit.CreateController({
	Name = "HomePlayerController",
	_Homes = {},
	_PlayerHome = nil,
	_isLock = false,
	_closestPlatform = nil,
	_grabBrainrot = nil,
})

--|| Local Functions ||--
-- Fungsi untuk hitung jarak player ↔ platform
local function GetDistanceFromPlatform(platform)
	if not platform then
		return math.huge
	end
	return (player.Character.HumanoidRootPart.Position - platform.Position).Magnitude
end

-- Fungsi untuk cari Platform terdekat dalam range tertentu
local function GetClosestPlatformInRange(range, platforms)
	local closest = nil
	local minDist = range
	if not platforms then
		return nil, nil
	end

	for _, platform in pairs(platforms) do
		local dist = GetDistanceFromPlatform(platform.platform)
		if dist < minDist then
			minDist = dist
			closest = platform
		end
	end

	return closest, minDist
end
-- Fungsi untuk cari Platform terdekat dalam range tertentu
local function GetClosestPlatformAllInRange(range, homes)
	local closest = nil
	local minDist = range
	if not homes then
		return nil, nil
	end

	for _, home in pairs(homes) do
		for _, platform in pairs(home.platforms) do
			local dist = GetDistanceFromPlatform(platform.platform)
			if dist < minDist then
				minDist = dist
				closest = platform
			end
		end
	end

	return closest, minDist
end

--|| Functions ||--
-- update setiap frame
function HomePlayerController:LoopController()
	RunService.RenderStepped:Connect(function()
		if self._PlayerHome == nil then
			return
		end
		local closest, dist
		if self._grabBrainrot then
			closest, dist = GetClosestPlatformInRange(20, self._PlayerHome.platforms)
		else
			closest, dist = GetClosestPlatformAllInRange(20, self._Homes)
		end

		if closest then
			self._closestPlatform = closest
		else
			self._closestPlatfrom = nil
		end
	end)
end
function HomePlayerController:InputHandle()
	UserInputService.InputBegan:Connect(function(input, processed)
		-- ignore if player is typing in chat or textbox
		if processed then
			return
		end

		-- detect E key
		if input.KeyCode == Enum.KeyCode.E and self._grabBrainrot == nil then
			if not self._closestPlatform then
				return
			end
			self._grabBrainrot = self._closestPlatform.brainrot
			if self._grabBrainrot then
				BrainrotService:AttatchToPlayer(self._closestPlatform.platform.CFrame, self._grabBrainrot.id)
				ToolsController:DisableOtherTools()
			else
				print("no brainrot")
			end
		elseif input.KeyCode == Enum.KeyCode.E and self._grabBrainrot then
			if not self._closestPlatform then
				return
			end
			BrainrotService:MoveToPlatform(self._closestPlatform.id)
			ToolsController:EnableTools()
			self._grabBrainrot = nil
		end
		if input.KeyCode == Enum.KeyCode.R and self._grabBrainrot then
			BrainrotService:DetatchFromPlayer()
			ToolsController:EnableTools()
			self._grabBrainrot = nil
		end
	end)
end

function HomePlayerController:HomeUpdated(homes)
	self._Homes = homes
	for _, home in pairs(self._Homes) do
		if home.player == player then
			self._PlayerHome = home
			self._PlayerHome.dor.CanCollide = false
			self._islock = self._PlayerHome.islock
		end
	end
end
function HomePlayerController:CharacterAdded(homes)
	self._Homes = homes
	for _, home in pairs(self._Homes) do
		if home.player == player then
			self._PlayerHome = home
			self._PlayerHome.dor.Color = Color3.fromRGB(0, 255, 0)
			home.lock.Touched:Connect(function(hit)
				if self._islock then
					return
				end
				if hit.Parent == player.Character then
					if home.islock == false then
						self._islock = true
						HomePlayerService:LockHome()
					end
				end
			end)
		end
	end
end

function HomePlayerController:KnitStart()
	HomePlayerService = Knit.GetService("HomePlayerService")
	BrainrotService = Knit.GetService("BrainrotService")

	ToolsController = Knit.GetController("ToolsController")

	HomePlayerService.CharacterAdded:Connect(function(homes)
		self:CharacterAdded(homes)
	end)
	HomePlayerService.HomeUpdated:Connect(function(homes)
		self:HomeUpdated(homes)
	end)
	HomePlayerController:LoopController()
	HomePlayerController:InputHandle()
end

return HomePlayerController
