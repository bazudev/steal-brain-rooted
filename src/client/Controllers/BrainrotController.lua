-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Knit packages
local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)

-- Player
local player = Players.LocalPlayer
local testingNPC = workspace.TestingNPC

-- Services
local BrainrotService

-- TemplateController
local BrainrotController = Knit.CreateController({
	Name = "BrainrotController",
})

--|| Local Functions ||--

--|| Functions ||--
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
	BrainrotService = Knit.GetService("BrainrotService")

	print("BrainrotController on Start")

	BrainrotService.OnDefaultPathGenrated:Connect(function(waypoints)
		BrainrotController:DrawDefaultPath(waypoints)
	end)
	BrainrotService.BrainRootMoving:Connect(function(character)
		BrainrotController:PlayAnimation(character, "walk", "WalkAnim")
	end)
end

return BrainrotController
