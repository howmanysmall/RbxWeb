local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local RbxWeb = require(3254046154)
RbxWeb:Initialize(require)

local DEFAULT_DATA = {
	DataID = 0;
	Points = 0;
}

local GAME_VERSION = "V1"

local GameDataStore = RbxWeb:GetGeneric(RbxWeb:AddGeneric(
	"GameDataStore" .. (RunService:IsStudio() and "Testing" or "Release") .. GAME_VERSION,
	"Global",
	"PlayerData"
))

local function PlayerAdded(Player)
	local PlayerKey = GameDataStore:GetKey(Player.UserId)
	local Success, PlayerData = GameDataStore:GetAsync(PlayerKey)

	if Success and not PlayerData then
		PlayerData = DEFAULT_DATA
		GameDataStore:SetAsync(PlayerKey, PlayerData)
	end

	local Leaderstats = Instance.new("Folder")
	Leaderstats.Name = "leaderstats"
	Leaderstats.Parent = Player

	local Points = Instance.new("IntValue")
	Points.Name = "Points"
	Points.Value = PlayerData.Points
	Points.Parent = Leaderstats
end

local function PlayerRemoving(Player)
	local Leaderstats = Player:FindFirstChild("leaderstats")
	if Leaderstats then
		local PlayerKey = GameDataStore:GetKey(Player.UserId)
		local Success, PlayerData = GameDataStore:GetAsync(PlayerKey)

		if Success and PlayerData then
			GameDataStore:UpdateAsync(PlayerKey, function(OldData)
				local PreviousData = OldData or DEFAULT_DATA
				if PlayerData.DataID == PreviousData.DataID then
					PlayerData.DataID = PlayerData.DataID + 1
					PlayerData.Points = Leaderstats.Points.Value

					return PlayerData
				else
					-- Do not save!
					return nil
				end
			end)
		end
	end
end

game:BindToClose(function()
	for _, Player in ipairs(Players:GetPlayers()) do
		local Thread = coroutine.create(PlayerRemoving)
		coroutine.resume(Thread, Player)
	end
end)

Players.PlayerAdded:Connect(PlayerAdded)
Players.PlayerRemoving:Connect(PlayerRemoving)

while true do
	wait(5)

	-- This is faster in the new VM.
	for _, Player in ipairs(Players:GetPlayers()) do
		local Leaderstats = Player:FindFirstChild("leaderstats")
		if Leaderstats then
			local Points = Leaderstats:FindFirstChild("Points")
			if Points then
				Points.Value = Points.Value + 1
			end
		end
	end
end
