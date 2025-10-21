-- Knit Packages
local MarketplaceService = game:GetService("MarketplaceService")
local PathfindingService = game:GetService("PathfindingService")
local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

-- Services
local Players = game:GetService("Players")
local BrainrotService
local HomePlayerService

local ToolsService = Knit.CreateService({
	Name = "ToolsService",
	Client = {
		CharacterAdded = Knit.CreateSignal(),
	},
})

--|| Client Functions ||--
function ToolsService.Client:TakeDamage(player: Player, hit: Player)
	ToolsService:TakeDamage(player, hit)
end

function ToolsService.Client:TestEvent(player: Player): boolean
	return false
end

-- KNIT START
function ToolsService:TakeDamage(player: Player, hit: Player)
	print("hit player ")
	BrainrotService:DetatchFromPlayer(hit)
	HomePlayerService:BackToHome(hit)
end
function ToolsService:KnitStart()
	BrainrotService = Knit.GetService("BrainrotService")
	HomePlayerService = Knit.GetService("HomePlayerService")
	local function playerAdded(player: Player)
		player.CharacterAdded:Connect(function(character)
			self.Client.CharacterAdded:Fire(player, character)
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

return ToolsService
