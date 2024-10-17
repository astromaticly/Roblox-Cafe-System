-- Services
local players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local replicatedStorage = game:GetService("ReplicatedStorage")
local runService = game:GetService("RunService")

-- Knit and ProfileService
local Knit = require(replicatedStorage:WaitForChild("Packages").Knit)
local Promise = require(Knit.Util.Promise)
local ProfileService = require(replicatedStorage:WaitForChild("Packages").profileservice)
-- Template for profile
local TEMPLATE = require(script.Parent.Template)

-- Create DataService with Knit
local dataService = {
	Name = "ProfileService",
	client = {},
}

-- Other Services

-- Collection to store player profiles
dataService.Collection = {}

-- ProfileStore initialization
local profileStore = ProfileService.GetProfileStore("PlayerData", TEMPLATE)

-- Utility Functions

-- Profile Functions
local function playerAdded(player)
	return Promise.new(function(resolve, reject)
		local profile = profileStore:LoadProfileAsync("User_" .. player.UserId)
		if not profile then
			return reject("[ProfileService.LoadProfileAsync]: Failed to load profile")
		end

		profile:AddUserId(player.UserId)
		profile:Reconcile()

		profile:ListenToRelease(function()
			player:Kick("[Profile.playerAdded]: Your data is loaded in a different server, please rejoin.")
		end)

		dataService.Collection[player.UserId] = profile
		resolve(profile)
	end)
end

local function playerRemoving(player)
	local profile = dataService.Collection[player.UserId]
	local hour_endtime = os.date("!*t").hour
	local min_endtime = os.date("!*t").min

	local hour_start, min_start = table.unpack(profile.TimeJoined)
	local time_start = hour_start .. ":" .. min_start
	local time_end = hour_endtime .. ":" .. min_endtime

	if profile then
		profile:Release()
		dataService.Collection[player.UserId] = nil
		print("💾 Save Successful")
	end
end

-- DataService Methods
function dataService:UpdateProfile(player, key, value)
	local profile = self:GetProfile(player)
	if profile then
		profile.Data[key] = value
		return true
	else
		warn("[ProfileService.UpdateProfile]: No profile found for player")
		return false
	end
end

function dataService:UpdateBank(player, cash, balance)
	local profile = dataService.Collection[player.UserId]
	if profile then
		profile.Data.Player.Bank.Cash = cash
		profile.Data.Player.Bank.Balance = balance
		return true
	else
		warn("[ProfileService.UpdateBank]: No profile found for player")
		return false
	end
end

function dataService:SaveProfile(player)
	return Promise.new(function(resolve, reject)
		local profile = dataService.Collection[player.UserId]
		if profile then
			profile:Release()
			self.Collection[player.UserId] = profileStore:LoadProfileAsync("User_" .. player.UserId)
			print("Profile saved for player:", player.Name)
			resolve(true)
		else
			reject("[ProfileService.SaveProfile]: No profile found for player")
			return false
		end
	end)
end

function dataService:EraseData(player)
	local profile = dataService.Collection[player.UserId]
	if profile then
		for k in pairs(profile.Data) do
			profile.Data[k] = nil
		end
		print("Profile data erased for player:", player.Name .. ":" .. player.UserId)
		return true
	else
		warn("[ProfileService.EraseProfile]: No profile found for player")
		return false
	end
end

function dataService:KnitInit() end

function dataService:KnitStart()
	for _, player in ipairs(players:GetPlayers()) do
		task.spawn(playerAdded, player)
	end

	players.PlayerAdded:Connect(function(player)
		local promise = playerAdded(player)

		promise
			:andThen(function(data)
				dataService.Collection[player.UserId] = data
			end)
			:catch(function(error_message)
				warn("[ProfileService.playerAdded]: " .. error_message)
			end)
	end)

	players.PlayerRemoving:Connect(playerRemoving)

	if not runService:IsStudio() then
		game:BindToClose(function()
			for _, player in ipairs(players:GetPlayers()) do
				playerRemoving(player)
			end
		end)
	end
end

-- Function to get player profile
function dataService:GetProfile(player)
	repeat
		task.wait()
	until dataService.Collection[player.UserId]

	return dataService.Collection[player.UserId].Data
end

return dataService
