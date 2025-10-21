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

function ToolsService.Client:TestEvent(player: Player): boolean
	return false
end

-- KNIT START
function ToolsService:TakeDamage(hit: Player)
	print("hit player ")
	BrainrotService:DetatchFromPlayer(hit)
	HomePlayerService:BackToHome(hit)
end
function ToolsService:SetupTool(player)
	local backpack = player:WaitForChild("Backpack")
	print("setup tools", backpack, backpack:GetChildren())
	for _, item in ipairs(backpack:GetChildren()) do
		print(item.Name, item:IsA("Tool"))
		if item.Name == "Baseballbat" and item:IsA("Tool") then
			local body = item:WaitForChild("Bat")
			body.Touched:Connect(function(hit)
				if not hit or not hit.Parent then
					return
				end
				local Humanoid = hit.Parent:FindFirstChildOfClass("Humanoid")
				if Humanoid then
					ToolsService:TakeDamage(hit.Parent)
				end
			end)
		end
	end
end
function ToolsService:KnitStart()
	BrainrotService = Knit.GetService("BrainrotService")
	HomePlayerService = Knit.GetService("HomePlayerService")
	local function playerAdded(player: Player)
		player.CharacterAdded:Connect(function(character)
			self.Client.CharacterAdded:Fire(player, character)
			ToolsService:SetupTool(player)
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
