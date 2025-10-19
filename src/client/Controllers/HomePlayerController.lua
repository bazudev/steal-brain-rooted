-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Knit packages
local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)

-- Player
local player = Players.LocalPlayer

-- Services
local HomePlayerService

-- TemplateController
local HomePlayerController = Knit.CreateController({
	Name = "HomePlayerController",
	_Homes = {},
	_PlayerHome = nil,
	_isLock = false,
})

--|| Local Functions ||--

--|| Functions ||--
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
	HomePlayerService.CharacterAdded:Connect(function(homes)
		self:CharacterAdded(homes)
	end)
	HomePlayerService.HomeUpdated:Connect(function(homes)
		self:HomeUpdated(homes)
	end)
end

return HomePlayerController
