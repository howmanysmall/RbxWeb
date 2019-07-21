-- Original RbxWeb was made by movsb. This rewrite was done entirely by howmanysmaII.
-- There's an example script inside this script, which will show you how to use this module with no data loss.
-- For an easy way to read the documentation, install Documentation Reader. https://www.roblox.com/library/1836614749/Documentation-Reader

local Players = game:GetService("Players")

local assert = assert
local typeof = typeof

local RbxWeb = { }

local CurrentLength = #Players:GetPlayers() do
	local function PlayerAdded()
		CurrentLength = CurrentLength + 1
	end

	local function PlayerRemoving()
		CurrentLength = CurrentLength - 1
	end

	Players.PlayerAdded:Connect(PlayerAdded)
	Players.PlayerRemoving:Connect(PlayerRemoving)
end

local DataStoreService = nil
local DataStores = { }
local Yield = false
local StandardWait = 0.5
local ErrorFunction = warn
local UsingMock = false

local function GetGenericYieldTime()
	return 60 / (60 + CurrentLength * 10)
end

local function GetSortYieldTime()
	return 60 / (5 + CurrentLength * 2)
end

local function PushGenericQueue(Callback, Yielder)
	if not Yield then
		Yield = true
		local Data = { Callback() }
		wait(Yielder())
		Yield = false
		return unpack(Data)
	else
		wait(StandardWait)
		return PushGenericQueue(Callback, Yielder)
	end
end

local TypeCache = { }

local function BetterTypeOf(Object, DictionaryReplacesTable, FloatReplacesNumber)
	local ObjectType = typeof(Object)
	if ObjectType == "table" then
		local IsArray = (function()
			local Length = #Object
			if Length == 0 then return false end

			for Index = 1, Length do
				local Value = Object[Index]
				if Value == nil then return false end
				Object[Index] = nil
				TypeCache[Index] = Value
			end

			if next(Object) then return false end

			for Index = 1, Length do
				Object[Index] = TypeCache[Index]
				TypeCache[Index] = nil
			end

			return true
		end)()

		return IsArray and "array" or (DictionaryReplacesTable and "dictionary" or "table")
	elseif ObjectType == "number" then
		return Object % 1 == 0 and "integer" or (FloatReplacesNumber and "float" or "number")
	else
		return ObjectType
	end
end

--[[**
	Initializes RbxWeb.
	@param [InstanceOrFunction] DataModel This should either be `game` for the default DataStoreService or `require` for MockDataStoreService.
	@returns void
**--]]
function RbxWeb:Initialize(DataModel)
	if not DataStoreService then
		local Type = typeof(DataModel)
		if Type == "Instance" and DataModel == game then
			DataStoreService, UsingMock = DataModel:GetService("DataStoreService"), false
		elseif Type == "function" and DataModel == require then -- Can't be too safe.
			DataStoreService, UsingMock = unpack(DataModel(script.DataStoreService))
			print(UsingMock)
		end
	else
		warn("RbxWeb is already initialized!", debug.traceback(2))
	end
end

--[[**
	Sets the standard wait time between each retry.
	@param [PositiveNumber] NewTime The new standard wait time. This will be set to 0.5 if it is below it.
	@returns void
**--]]
function RbxWeb:SetStandardWait(NewTime)
	StandardWait = NewTime >= 0.5 and NewTime or 0.5
end

--[[**
	Sets the error function that is called when something goes wrong.
	@param [Function] Function The function that will be called. Recommended to either use error or warn.
	@returns void
**--]]
function RbxWeb:SetErrorFunction(Function)
	ErrorFunction = Function
end

--[[**
	Adds a generic (global) DataStore to RbxWeb.
	@param [String] Key The key of the GlobalDataStore.
	@param [OptionalString] Scope The scope of the GlobalDataStore.
	@param [OptionalString] Prefix The prefix of the player keys. Defaults to an empty string.
	@returns [GlobalDataStore] Your generic DataStore.
**--]]
function RbxWeb:AddGeneric(Key, Scope, Prefix)
	assert(type(Key) == "string", ("bad argument #1 in RbxWeb::AddGeneric (string expected, instead got %s)"):format(typeof(Key)))
	assert(type(Scope) == "string" or Scope == nil, ("bad argument #2 in RbxWeb::AddGeneric (string expected, instead got %s)"):format(typeof(Scope)))
	assert(type(Prefix) == "string" or Prefix == nil, ("bad argument #3 in RbxWeb::AddGeneric (string expected, instead got %s)"):format(typeof(Prefix)))

	local KeyPrefix = Prefix or ""
	local DataStore = DataStoreService:GetDataStore(Key, Scope)
	DataStores[DataStore] = KeyPrefix
	return DataStore
end

--[[**
	Adds a ordered DataStore to RbxWeb.
	@param [String] Key The key of the OrderedDataStore.
	@param [OptionalString] Scope The scope of the OrderedDataStore. Defaults to global.
	@param [OptionalString] Prefix The prefix of the player keys. Defaults to an empty string.
	@returns [OrderedDataStore] Your ordered DataStore.
**--]]
function RbxWeb:AddOrdered(Key, Scope, Prefix)
	assert(type(Key) == "string", ("bad argument #1 in RbxWeb::AddOrdered (string expected, instead got %s)"):format(typeof(Key)))
	assert(type(Scope) == "string" or Scope == nil, ("bad argument #2 in RbxWeb::AddOrdered (string expected, instead got %s)"):format(typeof(Scope)))
	assert(type(Prefix) == "string" or Prefix == nil, ("bad argument #3 in RbxWeb::AddOrdered (string expected, instead got %s)"):format(typeof(Prefix)))

	local KeyPrefix = Prefix or ""
	local DataStore = DataStoreService:GetOrderedDataStore(Key, Scope)
	DataStores[DataStore] = KeyPrefix
	return DataStore
end

local ACCEPTED_DATA_STORE_TYPES = {
	["table"] = true;
	["boolean"] = true;
	["string"] = true;
	["number"] = true;
--	["nil"] = maybe?;
}

--[[**
	Gets the methods of the given GlobalDataStore.
	@param [GlobalDataStore] DataRoot The GlobalDataStore you are using.
	@returns [RbxWebGenericClass] The GenericDataStore class with all the methods you can work with.
**--]]
function RbxWeb:GetGeneric(DataRoot)
	local DataRootType = typeof(DataRoot)
	if UsingMock then
		assert(DataRootType == "table", ("bad argument #1 in RbxWeb::GetGeneric (table expected, instead got %s)"):format(DataRootType))
		assert(DataRoot.__type == "GlobalDataStore", ("bad argument #1 in RbxWeb::GetGeneric (GlobalDataStore expected, instead got %s)"):format(tostring(DataRootType.__type)))
	else
		assert(DataRootType == "Instance", ("bad argument #1 in RbxWeb::GetGeneric (Instance expected, instead got %s)"):format(DataRootType))
		assert(DataRoot:IsA("GlobalDataStore"), ("bad argument #1 in RbxWeb::GetGeneric (GlobalDataStore expected, instead got %s)"):format(DataRoot.ClassName))
	end

	local Generic = { }
	local GenericMeta = {
		__index = function(_, Index)
			return ({ Prefix = DataStores[DataRoot] })[Index]
		end;
	}

	--[[**
		Gets the key. Recommended you pass a UserId for player data.
		@param [NonNil] Data The data used for the key. It is suggested that you use a UserId when dealing with player data.
		@returns [String] The key requested.
	**--]]
	function Generic:GetKey(Data)
		assert(Data ~= nil, "bad argument #1 in Generic::GetKey (expected non-nil, got nil)")
		return self.Prefix .. Data
	end

	--[[**
		Same as GlobalDataStore::GetAsync. This function returns the value of the entry in the GlobalDataStore with the given key. If the key does not exist, returns nil. This function caches for about 4 seconds, so you cannot be sure that it returns the current value saved on the Roblox servers.
		@param [String] Key The key you wish to get data from.
		@returns [Tuple<Boolean, Variant>] Whether or not the attempt was successful and the value saved.
	**--]]
	function Generic:GetAsync(Key)
		assert(type(Key) == "string", ("bad argument #1 in Generic::GetAsync (string expected, got %s)"):format(typeof(Key)))

		local Success, Data = PushGenericQueue(function()
			return pcall(DataRoot.GetAsync, DataRoot, Key)
		end, GetGenericYieldTime)

		if not Success then
			ErrorFunction("Error in GetAsync for GlobalDataStore \"" .. tostring(DataRoot) .. "\":\n" .. tostring(Data))
		end

		return Success, Data
	end

	--[[**
		Same as GlobalDataStore::SetAsync. Sets the value of the key. This overwrites any existing data stored in the key. It's not recommended you use this when the previous data is important.
		@param [String] Key The key identifying the entry being retrieved from the DataStore.
		@param [TableOrBooleanOrStringOrNumber] Value The value of the entry in the DataStore with the given key.
		@returns [Tuple<Boolean, String>] Whether or not the attempt was successful and the possible error message if not successful.
	**--]]
	function Generic:SetAsync(Key, Value)
		assert(type(Key) == "string", ("bad argument #1 in Generic::SetAsync (string expected, got %s)"):format(typeof(Key)))
		local ValueType = typeof(Value)
		assert(ACCEPTED_DATA_STORE_TYPES[ValueType] == true, ("bad argument #2 in Generic::SetAsync (table, boolean, string, or number expected, got %s)"):format(ValueType))

		local Success, Error = PushGenericQueue(function()
			return pcall(DataRoot.SetAsync, DataRoot, Key, Value)
		end, GetGenericYieldTime)

		if not Success then
			ErrorFunction("Error in SetAsync for GlobalDataStore \"" .. tostring(DataRoot) .. "\":\n" .. tostring(Error))
		end

		return Success, Error
	end

	--[[**
		Same as GlobalDataStore::UpdateAsync. This function retrieves the value of a key from a DataStore and updates it with a new value. Since this function validates the data, it should be used in favor of SetAsync() when there's a chance that more than one server can edit the same data at the same time.
		@param [String] Key The key identifying the entry being retrieved from the DataStore.
		@param [Function] Callback A function which you need to provide. The function takes the key's old value as input and returns the new value.
		@returns [Tuple<Boolean, Variant>] Whether or not the attempt was successful and the value of the entry in the DataStore with the given key.
	**--]]
	function Generic:UpdateAsync(Key, Callback)
		assert(type(Key) == "string", ("bad argument #1 in Generic::UpdateAsync (string expected, got %s)"):format(typeof(Key)))
		assert(type(Callback) == "function", ("bad argument #2 in Generic::UpdateAsync (function expected, got %s)"):format(typeof(Callback)))

		local Success, Error = PushGenericQueue(function()
			return pcall(DataRoot.UpdateAsync, DataRoot, Key, Callback)
		end, GetGenericYieldTime)

		if not Success then
			ErrorFunction("Error in UpdateAsync for GlobalDataStore \"" .. tostring(DataRoot) .. "\":\n" .. tostring(Error))
		end

		return Success, Error
	end

	--[[**
		Same as GlobalDataStore::RemoveAsync. This function removes the given key from the provided GlobalDataStore and returns the value that was associated with that key. If the key is not found in the DataStore, this function returns nil.
		@param [String] Key The key identifying the entry being retrieved from the DataStore.
		@returns [Tuple<Boolean, Variant>] Whether or not the attempt was successful and the value that was associated with the DataStore key, or nil if the key was not found.
	**--]]
	function Generic:RemoveAsync(Key)
		assert(type(Key) == "string", ("bad argument #1 in Generic::RemoveAsync (string expected, got %s)"):format(typeof(Key)))

		local Success, Data = PushGenericQueue(function()
			return pcall(DataRoot.RemoveAsync, DataRoot, Key)
		end, GetGenericYieldTime)

		if not Success then
			ErrorFunction("Error in RemoveAsync for GlobalDataStore \"" .. tostring(DataRoot) .. "\":\n" .. tostring(Data))
		end

		return Success, Data
	end

	--[[**
		Same as GlobalDataStore::IncrementAsync. Increments the value for a particular key and returns the incremented value. Only works on values that are integers. Note that you can use OnUpdate() to execute a function every time the database updates the key's value, such as after calling this function.
		@param [String] Key The key identifying the entry being retrieved from the DataStore.
		@param [OptionalInteger] Delta The increment amount.
		@returns [Tuple<Boolean, Variant>] Whether or not the attempt was successful and the value of the entry in the DataStore with the given key.
	**--]]
	function Generic:IncrementAsync(Key, Delta)
		assert(type(Key) == "string", ("bad argument #1 in Generic::IncrementAsync (string expected, got %s)"):format(typeof(Key)))
		local DeltaType = BetterTypeOf(Delta, false, true)
		assert(DeltaType == "integer", ("bad argument #2 in Generic::IncrementAsync (integer expected, got %s)"):format(DeltaType))

		local Success, Data = PushGenericQueue(function()
			return pcall(DataRoot.IncrementAsync, DataRoot, Key, Delta)
		end, GetGenericYieldTime)

		if not Success then
			ErrorFunction("Error in IncrementAsync for GlobalDataStore \"" .. tostring(DataRoot) .. "\":\n" .. tostring(Data))
		end

		return Success, Data
	end

	-- Legacy RbxWeb API
	Generic.__GetKey = Generic.GetKey
	Generic.__GetAsync = Generic.GetAsync
	Generic.__NewAsync = Generic.SetAsync
	Generic.__SaveAsync = Generic.UpdateAsync
	Generic.__DelAsync = Generic.RemoveAsync
	Generic.__IncAsync = Generic.IncrementAsync

	return setmetatable(Generic, GenericMeta)
end

--[[**
	Gets the methods of the given OrderedDataStore.
	@param [OrderedDataStore] DataRoot The OrderedDataStore you are using.
	@returns [RbxWebOrderedClass] The OrderedDataStore class with all the methods you can work with.
**--]]
function RbxWeb:GetOrdered(DataRoot)
	local DataRootType = typeof(DataRoot)
	if UsingMock then
		assert(DataRootType == "table", ("bad argument #1 in RbxWeb::GetOrdered (table expected, instead got %s)"):format(DataRootType))
		assert(DataRoot.__type == "OrderedDataStore", ("bad argument #1 in RbxWeb::GetOrdered (OrderedDataStore expected, instead got %s)"):format(tostring(DataRootType.__type)))
	else
		assert(DataRootType == "Instance", ("bad argument #1 in RbxWeb::GetOrdered (Instance expected, instead got %s)"):format(DataRootType))
		assert(DataRoot:IsA("OrderedDataStore"), ("bad argument #1 in RbxWeb::GetOrdered (OrderedDataStore expected, instead got %s)"):format(DataRoot.ClassName))
	end

	local Ordered = { }
	local OrderedMeta = {
		__index = function(_, Index)
			return ({ Prefix = DataStores[DataRoot] })[Index]
		end;
	}

	--[[**
		Same as OrderedDataStore::GetSortedAsync, except for it goes through the DataStorePages for you.
		@param [OptionalBoolean] Ascend A boolean indicating whether the returned data pages are in ascending order. Defaults to false.
		@returns [Tuple<Boolean, Variant>] Whether or not the attempt was successful and the values of the DataStorePages.
	**--]]
	function Ordered:CollectData(Ascend)
		local IsAscending = Ascend or false
		assert(type(IsAscending) == "boolean", ("bad argument #1 in Ordered::CollectData (expected boolean, got %s)"):format(typeof(IsAscending)))

		local DataTable = { }
		local Success, Data = PushGenericQueue(function()
			return pcall(DataRoot.GetSortedAsync, DataRoot, IsAscending, 100)
		end, GetSortYieldTime)

		if not Success then
			ErrorFunction("Error in CollectData for OrderedDataStore \"" .. tostring(DataRoot) .. "\":\n" .. tostring(Data))
			return Success, Data
		else
			while true do
				local PageSuccess, PageData = pcall(Data.GetCurrentPage, Data)
				if PageSuccess then
					for _, Value in pairs(PageData) do DataTable[Value.key] = Value.value end
					if Data.IsFinished then break end
				else
					ErrorFunction("Error in GetCurrentPage for OrderedDataStore \"" .. tostring(DataRoot) .. "\":\n" .. tostring(PageData))
					return PageSuccess, PageData
				end

				local NextPageSuccess, NextPageError = pcall(Data.AdvanceToNextPageAsync, Data)
				if not NextPageSuccess then
					ErrorFunction("Error in AdvanceToNextPageAsync for OrderedDataStore \"" .. tostring(DataRoot) .. "\":\n" .. tostring(NextPageError))
					return NextPageSuccess, NextPageError
				end
			end
		end

		return Success, DataTable
	end

	--[[**
		Gets the key. Recommended you pass a UserId for player data.
		@param [Variant] Data The data used for the key. It is suggested that you use a UserId when dealing with player data.
		@returns [String] The key requested.
	**--]]
	function Ordered:GetKey(Data)
		assert(Data ~= nil, "bad argument #1 in Ordered::GetKey (expected non-nil, got nil)")
		return self.Prefix .. Data
	end

	--[[**
		Same as OrderedDataStore::GetAsync. This function returns the value of the entry in the OrderedDataStore with the given key. If the key does not exist, returns nil. This function caches for about 4 seconds, so you cannot be sure that it returns the current value saved on the Roblox servers.
		@param [String] Key The key you wish to get data from.
		@returns [Tuple<Boolean, Variant>] Whether or not the attempt was successful and the value saved.
	**--]]
	function Ordered:GetAsync(Key)
		assert(type(Key) == "string", ("bad argument #1 in Ordered::GetAsync (string expected, got %s)"):format(typeof(Key)))

		local Success, Data = PushGenericQueue(function()
			return pcall(DataRoot.GetAsync, DataRoot, Key)
		end, GetGenericYieldTime)

		if not Success then
			ErrorFunction("Error in GetAsync for OrderedDataStore \"" .. tostring(DataRoot) .. "\":\n" .. tostring(Data))
		end

		return Success, Data
	end

	--[[**
		Same as OrderedDataStore::SetAsync. Sets the value of the key. This overwrites any existing data stored in the key. It's not recommended you use this when the previous data is important.
		@param [String] Key The key identifying the entry being retrieved from the DataStore.
		@param [Variant] Value The value of the entry in the DataStore with the given key.
		@returns [Tuple<Boolean, String>] Whether or not the attempt was successful and the possible error message if not successful.
	**--]]
	function Ordered:SetAsync(Key, Value)
		assert(type(Key) == "string", ("bad argument #1 in Ordered::SetAsync (string expected, got %s)"):format(typeof(Key)))
		local ValueType = typeof(Value)
		assert(ACCEPTED_DATA_STORE_TYPES[ValueType] == true, ("bad argument #2 in Ordered::SetAsync (table, boolean, string, or number expected, got %s)"):format(ValueType))

		local Success, Error = PushGenericQueue(function()
			return pcall(DataRoot.SetAsync, DataRoot, Key, Value)
		end, GetGenericYieldTime)

		if not Success then
			ErrorFunction("Error in SetAsync for OrderedDataStore \"" .. tostring(DataRoot) .. "\":\n" .. tostring(Error))
		end

		return Success, Error
	end

	--[[**
		Same as OrderedDataStore::UpdateAsync. This function retrieves the value of a key from a DataStore and updates it with a new value. Since this function validates the data, it should be used in favor of SetAsync() when there's a chance that more than one server can edit the same data at the same time.
		@param [String] Key The key identifying the entry being retrieved from the DataStore.
		@param [Function] Callback A function which you need to provide. The function takes the key's old value as input and returns the new value.
		@returns [Tuple<Boolean, Variant>] Whether or not the attempt was successful and the value of the entry in the DataStore with the given key.
	**--]]
	function Ordered:UpdateAsync(Key, Callback)
		assert(type(Key) == "string", ("bad argument #1 in Ordered::UpdateAsync (string expected, got %s)"):format(typeof(Key)))
		assert(type(Callback) == "function", ("bad argument #2 in Ordered::UpdateAsync (function expected, got %s)"):format(typeof(Callback)))

		local Success, Error = PushGenericQueue(function()
			return pcall(DataRoot.UpdateAsync, DataRoot, Key, Callback)
		end, GetGenericYieldTime)

		if not Success then
			ErrorFunction("Error in UpdateAsync for OrderedDataStore \"" .. tostring(DataRoot) .. "\":\n" .. tostring(Error))
		end

		return Success, Error
	end

	--[[**
		Same as OrderedDataStore::RemoveAsync. This function removes the given key from the provided OrderedDataStore and returns the value that was associated with that key. If the key is not found in the DataStore, this function returns nil.
		@param [String] Key The key identifying the entry being retrieved from the DataStore.
		@returns [Tuple<Boolean, Variant>] Whether or not the attempt was successful and the value that was associated with the DataStore key, or nil if the key was not found.
	**--]]
	function Ordered:RemoveAsync(Key)
		assert(type(Key) == "string", ("bad argument #1 in Ordered::RemoveAsync (string expected, got %s)"):format(typeof(Key)))

		local Success, Data = PushGenericQueue(function()
			return pcall(DataRoot.RemoveAsync, DataRoot, Key)
		end, GetGenericYieldTime)

		if not Success then
			ErrorFunction("Error in RemoveAsync for OrderedDataStore \"" .. tostring(DataRoot) .. "\":\n" .. tostring(Data))
		end

		return Success, Data
	end

	--[[**
		Same as OrderedDataStore::IncrementAsync. Increments the value for a particular key and returns the incremented value. Only works on values that are integers. Note that you can use OnUpdate() to execute a function every time the database updates the key's value, such as after calling this function.
		@param [String] Key The key identifying the entry being retrieved from the DataStore.
		@param [OptionalInteger] Delta The increment amount.
		@returns [Tuple<Boolean, Variant>] Whether or not the attempt was successful and the value of the entry in the DataStore with the given key.
	**--]]
	function Ordered:IncrementAsync(Key, Delta)
		assert(type(Key) == "string", ("bad argument #1 in Ordered::IncrementAsync (string expected, got %s)"):format(typeof(Key)))
		local DeltaType = BetterTypeOf(Delta, true, true)
		assert(DeltaType == "integer", ("bad argument #2 in Ordered::IncrementAsync (integer expected, got %s)"):format(DeltaType))

		local Success, Data = PushGenericQueue(function()
			return pcall(DataRoot.IncrementAsync, DataRoot, Key, Delta)
		end, GetGenericYieldTime)

		if not Success then
			ErrorFunction("Error in IncrementAsync for OrderedDataStore \"" .. tostring(DataRoot) .. "\":\n" .. tostring(Data))
		end

		return Success, Data
	end

	-- Legacy RbxWeb API
	Ordered.__CollectData = Ordered.CollectData
	Ordered.__GetKey = Ordered.GetKey
	Ordered.__GetAsync = Ordered.GetAsync
	Ordered.__NewAsync = Ordered.SetAsync
	Ordered.__SaveAsync = Ordered.UpdateAsync
	Ordered.__DelAsync = Ordered.RemoveAsync
	Ordered.__IncAsync = Ordered.IncrementAsync

	return setmetatable(Ordered, OrderedMeta)
end

RbxWeb.__Init = RbxWeb.Initialize
RbxWeb.__AddGeneric = RbxWeb.AddGeneric
RbxWeb.__AddOrdered = RbxWeb.AddOrdered
RbxWeb.__GetGeneric = RbxWeb.GetGeneric
RbxWeb.__GetOrdered = RbxWeb.GetOrdered

return RbxWeb
