
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

Knit.AddServicesDeep(script.Parent.Server.Services)

Knit.Start()
    :andThen(function()
        print("Knit Server Successfully Started")
    end)
    :catch(warn)
    :await()