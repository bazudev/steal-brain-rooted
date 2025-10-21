-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Knit packages
local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)

-- Player
local player = Players.LocalPlayer

-- Services
local ToolsService

-- TemplateController
local ToolsController = Knit.CreateController({
	Name = "ToolsController",
	_Tools = {},
})

--|| Local Functions ||--

--|| Functions ||--
function ToolsController:SetupTools()
	local backpack = player:WaitForChild("Backpack")
	print("setup tools", backpack, backpack:GetChildren())
	for _, item in ipairs(backpack:GetChildren()) do
		print(item.Name, item:IsA("Tool"))
		if item.Name == "Baseballbat" and item:IsA("Tool") then
			self:HandleBaseballBat(item)
			self:SetupAnimation(item)
		end
	end
end
function ToolsController:HandleBaseballBat(tool)
	tool.Equipped:Connect(function()
		print("baseball bat equipped")
	end)

	tool.Unequipped:Connect(function()
		print("baseball bat unequipped")
	end)
	local body = tool:WaitForChild("Bat")
	body.Touched:Connect(function(hit)
		if not hit or not hit.Parent then
			return
		end
		local Humanoid = hit.Parent:FindFirstChildOfClass("Humanoid")
		print("hit:", hit.Parent)
		ToolsService:TakeDamage(hit.Parent)
	end)
end
function ToolsController:SetupAnimation(tool)
	local character = player.Character or player.CharacterAdded:Wait()
	local Humanoid = character:WaitForChild("Humanoid")
	local animator = Humanoid:FindFirstChildOfClass("Animator")
	local anims = tool:WaitForChild("Animations"):WaitForChild(Humanoid.RigType.Name)
	local tracks = {
		Slash = animator:LoadAnimation(anims:WaitForChild("SlashAnim")),
		Stab = animator:LoadAnimation(anims:WaitForChild("StabAnim")),
		Summon = animator:LoadAnimation(anims:WaitForChild("SummonAnim")),
		Charge = animator:LoadAnimation(anims:WaitForChild("ChargeAnim")),
	}
	self._Tools[tool.Name] = {
		tool = tool,
		tracks = tracks,
	}

	tool.Activated:Connect(function()
		print("activated")
		tracks.Slash:Play()
	end)
end
function ToolsController:DisableOtherTools()
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")
	humanoid:UnequipTools()
	local backpack = player:WaitForChild("Backpack")
	for _, item in ipairs(backpack:GetChildren()) do
		item.Enabled = false
	end
end

function ToolsController:EnableTools()
	local backpack = player:WaitForChild("Backpack")
	for _, item in ipairs(backpack:GetChildren()) do
		item.Enabled = true
	end
end

function ToolsController:KnitInit() end

function ToolsController:KnitStart()
	ToolsService = Knit.GetService("ToolsService")

	print("ToolsController on Start")

	ToolsService.CharacterAdded:Connect(function(character)
		ToolsController:SetupTools()
	end)
end

return ToolsController
