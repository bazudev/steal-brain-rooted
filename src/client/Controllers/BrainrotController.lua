-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- Knit packages
local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)

-- Player
local player = Players.LocalPlayer

-- Services
local BrainrotService

-- variable
local TestingTargetPosition = Vector3.new(100, 0, 100)

-- TemplateController
local BrainrotController = Knit.CreateController({
	Name = "BrainrotController",
	_Brainrots = {},
	_closestBrainrot = nil,
})

--|| Local Functions ||--
-- Fungsi untuk hitung jarak player ↔ NPC
local function GetDistanceFromNPC(npcObject)
	if not npcObject then
		return math.huge
	end
	return (player.Character.HumanoidRootPart.Position - npcObject.HumanoidRootPart.Position).Magnitude
end

-- Fungsi untuk cari NPC terdekat dalam range tertentu
local function GetClosestNPCInRange(range, brainrots)
	local closest = nil
	local minDist = range
	if not brainrots then
		return nil, nil
	end

	for _, brain in pairs(brainrots) do
		local dist = GetDistanceFromNPC(brain.object)
		if dist < minDist then
			minDist = dist
			closest = brain
		end
	end

	return closest, minDist
end

--|| Functions ||--
-- update setiap frame
function BrainrotController:LoopController()
	RunService.RenderStepped:Connect(function()
		local closest, dist = GetClosestNPCInRange(20, self._Brainrots)

		if closest then
			self._closestBrainrot = closest.id
		else
			self._closestBrainrot = nil
		end
	end)
end
function BrainrotController:InputHandle()
	UserInputService.InputBegan:Connect(function(input, processed)
		-- ignore if player is typing in chat or textbox
		if processed then
			return
		end

		-- detect E key
		if input.KeyCode == Enum.KeyCode.E then
			if not self._closestBrainrot then
				return
			end
			print("target:", TestingTargetPosition)
			BrainrotService:ChangeWaypoint(self._closestBrainrot, TestingTargetPosition)
		end
	end)
end

function BrainrotController:PlayAnimation(character, animType, animName)
	local humanoid = character:WaitForChild("Humanoid")
	local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)
	local animate = character:WaitForChild("Animate")

	local animFolder = animate:FindFirstChild(animType)
	if not animFolder then
		warn(`Animation type '{animType}' not found!`)
		return
	end

	local anim = animFolder:FindFirstChild(animName)
	if not anim then
		warn(`Child '{animName}' not found in '{animType}'!`)
		return
	end

	local track = animator:LoadAnimation(anim)
	track.Looped = true
	track:Play()
	return track
end
function BrainrotController:AddBrainrot(id, brainrot)
	self._Brainrots[id] = brainrot
end
function BrainrotController:RemoveBrainrot(id)
	self._Brainrots[id] = nil
end

function BrainrotController:DrawDefaultPath(waypoints) -- Draw path waypoints
	for i, waypoint in ipairs(waypoints) do
		-- Create Dot
		local marker = Instance.new("Part")
		marker.Shape = Enum.PartType.Ball
		marker.Color = Color3.fromRGB(0, 255, 0)
		marker.Material = Enum.Material.Neon
		marker.Size = Vector3.new(0.4, 0.4, 0.4)
		marker.Anchored = true
		marker.CanCollide = false
		marker.Position = waypoint.Position
		marker.Parent = workspace

		-- Draw line and connect to the next dot
		if waypoints[i + 1] then
			local nextPos = waypoints[i + 1].Position
			local dist = (nextPos - waypoint.Position).Magnitude

			local line = Instance.new("Part")
			line.Anchored = true
			line.CanCollide = false
			line.Material = Enum.Material.Neon
			line.Color = Color3.fromRGB(255, 255, 0)
			line.Size = Vector3.new(0.2, 0.2, dist)
			line.CFrame = CFrame.new((waypoint.Position + nextPos) / 2, nextPos)
			line.Parent = workspace
		end
	end
end

function BrainrotController:KnitStart()
	local BasePlayer = workspace:WaitForChild("BasePlayer")
	TestingTargetPosition = BasePlayer:WaitForChild("target").Position
	BrainrotService = Knit.GetService("BrainrotService")

	print("BrainrotController on Start")

	BrainrotService.OnDefaultPathGenrated:Connect(function(waypoints)
		BrainrotController:DrawDefaultPath(waypoints)
	end)
	BrainrotService.BrainRootMoving:Connect(function(character)
		BrainrotController:PlayAnimation(character, "walk", "WalkAnim")
	end)
	BrainrotService.BrainRootAdded:Connect(function(id, brainrot)
		print("add brainrot")
		BrainrotController:AddBrainrot(id, brainrot)
	end)
	BrainrotService.BrainRootRemoved:Connect(function(id)
		BrainrotController:RemoveBrainrot(id)
	end)
	BrainrotController:LoopController()
	BrainrotController:InputHandle()
end

return BrainrotController
