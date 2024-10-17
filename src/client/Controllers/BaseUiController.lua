--// Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

--// Packages
local Knit = require(ReplicatedStorage.Packages.Knit)
local Fusion = require(ReplicatedStorage.Packages.Fusion)

local New = Fusion.New

local TestController = {
	Name = "TestController",
}

local app =
	New("ScreenGui"), {
		Parent = Players.LocalPlayer:FindFirstChildOfClass("PlayerGui"),
		IgnoreGuiInset = true,

		--[Children] = {},
	}

return TestController
