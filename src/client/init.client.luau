local ReplicatedStorage = game:GetService("ReplicatedStorage")

local KnitClient = require(ReplicatedStorage.Packages.Knit) 

KnitClient.AddControllersDeep(script.Parent.Client.Controllers)

KnitClient.Start()
		:andThen(function()
			print("Knit Client Successfully Started")
		end)
		:catch(warn)
		:await()