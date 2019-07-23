-- This assumes that you already have initialized RbxWeb.
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")
local RbxWeb = require(3254046154)

local PurchaseHistory = RbxWeb:GetGeneric(RbxWeb:AddGeneric(
	"PurchaseHistory" .. (RunService:IsStudio() and "Testing" or "Release"),
	"Global"
))

local DeveloperProducts = {
	[123456789] = function(ReceiptInfo, Player)
		local Leaderstats = Player:FindFirstChild("leaderstats")
		if Leaderstats then
			local Coins = Leaderstats:FindFirstChild("Coins")
			if Coins then
				Coins.Value = Coins.Value + 25
				return true
			else
				return false
			end
		else
			return false
		end
	end;
}

local ERROR_MESSAGE_1 = "An error occurred while processing a product purchase!\n\tProductId: %d\n\tPlayer: %s\n\tError: %s\n\t%s"
local ERROR_MESSAGE_2 = "An error occurred while saving a product purchase!\n\tProductId: %d\n\tPlayer: %s\n\tError: %s\n\t%s"
local PurchaseGranted = Enum.ProductPurchaseDecision.PurchaseGranted
local NotProcessedYet = Enum.ProductPurchaseDecision.NotProcessedYet

local function ProcessReceipt(ReceiptInfo)
	local PlayerKey = PurchaseHistory:GetKey(ReceiptInfo.PlayerId .. ":" .. ReceiptInfo.PurchaseId) do
		local Success, Value = PurchaseHistory:GetAsync(PlayerKey)
		if Success and Value then
			return PurchaseGranted
		end
	end

	local Player = Players:GetPlayerByUserId(ReceiptInfo.PlayerId)
	if not Player then return NotProcessedYet end

	local Handler
	for ProductID, Function in pairs(DeveloperProducts) do
		if ProductID == ReceiptInfo.ProductId then
			Handler = Function
			break
		end
	end

	if not Handler then return NotProcessedYet end
	local Success, Error = pcall(Handler, ReceiptInfo, Player)
	if not Success then
		warn(ERROR_MESSAGE_1:format(
			ReceiptInfo.ProductId,
			tostring(Player),
			tostring(Error),
			debug.traceback(2)
		))

		return NotProcessedYet
	end

	if not Error then return NotProcessedYet end
	Success, Error = PurchaseHistory:SetAsync(PlayerKey, true)

	if not Success then
		warn(ERROR_MESSAGE_2:format(
			ReceiptInfo.ProductId,
			tostring(Player),
			tostring(Error),
			debug.traceback(2)
		))

		print("Handler worked fine, purchase granted.")
	end

	return PurchaseGranted
end

MarketplaceService.ProcessReceipt = ProcessReceipt
