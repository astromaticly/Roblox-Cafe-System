--// Roblox Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local HttpService = game:GetService("HttpService")

--// Packages
local Knit = require(ReplicatedStorage.Packages.Knit)
local Maid = require(ReplicatedStorage.Packages.Maid)
local Promise = require(ReplicatedStorage.Packages.Promise)

--// Variables
local Assets = ReplicatedStorage:WaitForChild("Assets")
local QuestsFolder = script.Quests

-- Knit Services
local WorldService
local DataService

--// Service Definition
local QuestService = {
	Name = "QuestService",
	PlayerQuests = {},
	Quests = {}, 

	Client = {
		QuestAssigned = Knit.CreateSignal(),
	},
}

--// Local Functions

local function GetRandomQuest(attempts)
	attempts = attempts or 0

	if attempts > 3 then
		warn("Failed to get random quest after 3 attempts")
		return
	end
	
	local keys = {}
	for key in pairs(QuestService.Quests) do
		table.insert(keys, key)
	end

	if #keys == 0 then
		warn("No quests available")
		return
	end

	-- Pick a random quest
	local randomKey = keys[math.random(#keys)]
	local randomValue = QuestService.Quests[randomKey]

	if randomKey and randomValue then
		return randomKey, randomValue
	else
		return GetRandomQuest(attempts + 1)
	end
end

-- Check if the player already has the specified quest
local function PlayerHasQuest(player, questName)
	local playerQuests = QuestService.PlayerQuests[player.UserId]
	
	print(QuestService.PlayerQuests[player.UserId])

	if playerQuests then
		for index, value in playerQuests do
			if value[questName] then
				return true
			end
		end
	end
end

--// Player Management

-- Function to handle player joining the game
function QuestService:PlayerAdded(player)
	local data = DataService:Get(player, { "Quest", "ActiveQuests" })
	print(data)

	local currentTime = os.time()
	local currentDate = os.date("*t", currentTime).day

	self.PlayerQuests[player.UserId] = {}

	if not data or #data == 0 then
		print("No data, refreshing quests...")
		self:RefreshQuests(player, data)
	else

		for _, quest in ipairs(data) do
			local assignedTime = quest.AssignedTime or currentTime
			local assignedDate = os.date("*t", assignedTime)

			if assignedDate.day ~= currentDate.day or assignedDate.month ~= currentDate.month or assignedDate.year ~= currentDate.year then
				data = {}
				self:RefreshQuests(player, data)
				break
			end
		end
	end
end

-- Function to handle player leaving the game
function QuestService:PlayerRemoving(player)
	self.PlayerQuests[player.UserId] = nil
end

--// Quest Management

-- Generate a random quest
function QuestService:GenerateQuest()
	local questName, questData = GetRandomQuest()
	if questName and questData then
		return questName, questData
	end
end

-- Check if the new quest is a duplicate of existing quests
function QuestService:IsQuestDuplicate(newQuest, questData)
	for _, activeQuest in ipairs(questData) do
		if activeQuest.Name == newQuest.Name then
			return true
		end
	end
	return false
end

-- Refresh a player's quest list
function QuestService:RefreshQuests(player, questData)
	local currentTime = os.time()

	for i = 1, 3 do
		local newQuest = {}
		local questName, questDetails = self:GenerateQuest()

		if questName and questDetails then
			newQuest[questName] = questDetails
			newQuest[questName]["QuestId"] = HttpService:GenerateGUID(false)
			print(newQuest[questName]["QuestId"])

			table.insert(self.PlayerQuests[player.UserId], newQuest)
		end
	end
end

-- Claim a quest
function QuestService:OnClaim(player, questName)
	local quest = QuestService.Quests[questName]
	local hasQuest = PlayerHasQuest(player, questName)

	print(quest)

	if hasQuest then
		if quest and quest.callback then
			local questfoler = Instance.new("Folder", workspace.Framework)
			questfoler.Name "-"
			
			local callback = quest.callback()		
			return true, callback
		else
			warn("Failed to callback quest: " .. questName .. ". Either the quest is nil or has no callback function.")
			return false
		end
	else
		warn(player.Name.." does not have the quest: ".. questName)
		return false
	end
end

-- Get the list of quests assigned to a player
function QuestService:GetQuests(player)
	local quests = self.PlayerQuests[player.UserId]
	if quests then
		return quests
	else
		warn("Error retrieving quests for player.")
		return nil
	end
end

--// Client Functions

-- Client-side function to get quests for a player
function QuestService.Client:GetQuests(player)
	return QuestService:GetQuests(player)
end

-- Client-side function to handle quest claiming
function QuestService.Client:OnClaim(player, questName) 
	return QuestService:OnClaim(player, questName)
end

--// Knit Lifecycle

-- Initialize services and dependencies
function QuestService:KnitInit()
	DataService = Knit.GetService("DataService")
end

-- Start service and initialize quests
function QuestService:KnitStart()
	for _, quest in QuestsFolder:GetChildren() do
		if quest:IsA("ModuleScript") then
			self.Quests[quest.Name] = require(quest)
		end
	end

	-- Connect player addition/removal events
	Players.PlayerAdded:Connect(function(player)
		self:PlayerAdded(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self:PlayerRemoving(player)
	end)
end

return QuestService
