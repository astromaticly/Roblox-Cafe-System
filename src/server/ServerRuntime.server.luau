--// Last Updated - 04/10/24

--// Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

--// Packages
local Knit = require(ReplicatedStorage.Packages.Knit)
local ServerTime = require(ReplicatedStorage.Common.Libraries.ServerTime)

--// Variables
local Services = script.Parent.Source.Services
local Components = script.Parent.Source.Components

--// Core
print("⚡️ Knit Server is starting...")
local start = tick()

for _, v in Services:GetDescendants() do
	if v:IsA("ModuleScript") and v.Name:match("Service$") then
		Knit.CreateService(require(v))
		print(string.format("Service %s", tostring(v.Name) .. " has started."))
	end
end

Knit.Start()
	:andThen(function()
		Knit.Components = {}

		for _, c in Components:GetDescendants() do
			if c:IsA("ModuleScript") then
				Knit.Components[c.Name] = require(c)
				print(string.format("Component %s", tostring(c.Name) .. " has started."))
			end
		end
	end)
	:catch(warn)
	:await()

Knit.OnStart()
	:andThen(function()
		task.wait()
		ReplicatedStorage:SetAttribute("KnitLoaded", true)
		ServerTime.run()

		local currentTime = tick()
		local final = (currentTime - start)
		print(
			"✅ Knit has successfully loaded on the server. Game Version: "
				.. tostring(game.PlaceVersion)
				.. " ["
				.. string.sub(final, 1, 4)
				.. "ms]"
		)
	end)
	:catch(warn)

game:BindToClose(function()
	task.wait()
	print(string.format("♻️ Game Shutdown in Progress"))
end)
