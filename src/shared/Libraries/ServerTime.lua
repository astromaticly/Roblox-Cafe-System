-- Syrchronized time

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ServerTime = {}

local _timeOffset = 0
local _serverTime = ReplicatedStorage:FindFirstChild("ServerTime")

if not _serverTime then
	_serverTime = Instance.new("NumberValue")
	_serverTime.Name = "ServerTime"
	_serverTime.Parent = ReplicatedStorage
end

local function _update()
	_serverTime.Value = tick() - _timeOffset
end

function ServerTime.run()
	_timeOffset = tick()
	_update()

	RunService.Stepped:Connect(_update)
end

--
return ServerTime
