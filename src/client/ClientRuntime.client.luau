--// Last Updated - 04/10/24

--// Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

--// Packages
local Knit = require(ReplicatedStorage.Packages.Knit)
local ServerTime = require(ReplicatedStorage.Common.Libraries.ServerTime)

--// Variables
local Controllers = script.Parent.Controllers
local Components = script.Parent.Components

--// Core

if game:GetAttribute("Initialized") == false then --It must be false, not nil
	warn("⚠️ Loading Screen is Running")
	warn("🛑 Client is Waiting for Loading Screen")
	ReplicatedStorage:GetAttributeChangedSignal("KnitLoaded"):Wait()
end

if not game:IsLoaded() then
	print("🛑 Knit Client is Waiting for Replication")
	game.Loaded:Wait()
end

if not ReplicatedStorage:GetAttribute("KnitLoaded") then
	warn("🛑 Client is Waiting for Knit Server Load")
	ReplicatedStorage:GetAttributeChangedSignal("KnitLoaded"):Wait()
end

local start = tick()
print("⚡️ Client is starting.")

for _, v in Controllers:GetDescendants() do
	if v:IsA("ModuleScript") and v.Name:match("Controller$") or v.Name:match("Gui$") then
		Knit.CreateController(require(v))
		print(string.format("Controller %s", tostring(v.Name) .. " has started."))
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

Knit.OnStart()
	:andThen(function()
		task.wait()
		local currentTime = tick()
		local final = (currentTime - start)

		print(
			"Client has successfully loaded. Game Version: "
				.. tostring(game.PlaceVersion)
				.. " ["
				.. string.sub(final, 1, 4)
				.. "ms]"
		)
		print("------------------------[[ REPORT ANY ERRORS BELOW THIS LINE ]]------------------------")
	end)
	:catch(warn)
