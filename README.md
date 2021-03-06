# RbxWeb
RbxWeb is a DataStoreService wrapper with the goal of being easy to use and preventing data loss in mind. The API is very similar to the vanilla DataStoreService which makes switching to RbxWeb very easy. The script is also documented entire, and can be read using [Documentation Reader](https://www.roblox.com/library/1836614749/Documentation-Reader). The script also supports using [MockDataStoreService](https://github.com/buildthomas/MockDataStoreService/) for easy offline testing.

This was originally made by my friend [movsb](https://www.roblox.com/users/77284141/profile). He made the original module for a game I was working on, and I've used it a lot since. Check out his [custom language L+](https://www.roblox.com/library/752810648/L-Programming-Suite) if you like custom languages or C.

The example script below is a demo of how to use RbxWeb, as well as how to use it properly to prevent loss of data.

## Example Script
```Lua
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
	local Success, PlayerData = GameDataStore:FixMissing(PlayerKey, DEFAULT_DATA, true)
	if not Success then warn("DataStores are experiencing issues, maybe.") end

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

Players.PlayerAdded:Connect(PlayerAdded)
Players.PlayerRemoving:Connect(PlayerRemoving)

game:BindToClose(function()
	for _, Player in ipairs(Players:GetPlayers()) do
		local Thread = coroutine.create(PlayerRemoving)
		coroutine.resume(Thread, Player)
	end
end)

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
```

## Features

- Much easier to use than DataStore2, while also being easier on performance as well as not creating a new DataStore every time.
- Similar API to DataStoreService.
- Can prevent loss of data if utilized properly.
- Automatic retrying calculated based off of the limits described [here](https://developer.roblox.com/en-us/articles/Datastore-Errors).
- Built in support for MockDataStoreService.
- Lots of type checking to make sure nothing can be done incorrectly.
- Documentated entirely through and through.
- Functions are automatically pcall-ed and will return two values as such.
- GetSortedAsync automatically iterates through DataStorePages for you.

## Documentation
<details>
<summary><code>function RbxWeb:Initialize(DataModel)</code></summary>

Initializes RbxWeb. Should only be called once.

**Parameters:**
- `[InstanceOrFunction]`  
DataModel This should either be `game` for the default DataStoreService or `require` for MockDataStoreService.

**Returns:**  
void

</details>

<details>
<summary><code>function RbxWeb:SetStandardWait(NewTime)</code></summary>

Sets the standard wait time between each retry.

**Parameters:**
- `[PositiveNumber]`  
NewTime The new standard wait time. This will be set to 0.5 if it is below it.

**Returns:**  
void

</details>

<details>
<summary><code>function RbxWeb:SetErrorFunction(Function)</code></summary>

Sets the error function that is called when something goes wrong.

**Parameters:**
- `[Function]`  
Function The function that will be called. Recommended to either use error or warn.

**Returns:**  
void

</details>

<details>
<summary><code>function RbxWeb:AddGeneric(Key, Scope, Prefix)</code></summary>

Adds a generic (global) DataStore to RbxWeb.

**Parameters:**
- `[String]`  
Key The key of the GlobalDataStore.
- `[OptionalString]`  
Scope The scope of the GlobalDataStore.
- `[OptionalString]`  
Prefix The prefix of the player keys. Defaults to an empty string.

**Returns:**  
[GlobalDataStore] Your generic DataStore.

</details>

<details>
<summary><code>function RbxWeb:AddOrdered(Key, Scope, Prefix)</code></summary>

Adds a ordered DataStore to RbxWeb.

**Parameters:**
- `[String]`  
Key The key of the OrderedDataStore.
- `[OptionalString]`  
Scope The scope of the OrderedDataStore. Defaults to global.
- `[OptionalString]`  
Prefix The prefix of the player keys. Defaults to an empty string.

**Returns:**  
[OrderedDataStore] Your ordered DataStore.

</details>

<details>
<summary><code>function RbxWeb:GetGeneric(DataRoot)</code></summary>

Gets the methods of the given GlobalDataStore.

**Parameters:**
- `[GlobalDataStore]`  
DataRoot The GlobalDataStore you are using.

**Returns:**  
[RbxWebGenericClass] The GenericDataStore class with all the methods you can work with.

</details>

<details>
<summary><code>function Generic:GetKey(Data)</code></summary>

Gets the key. Recommended you pass a UserId for player data.

**Parameters:**
- `[NonNil]`  
Data The data used for the key. It is suggested that you use a UserId when dealing with player data.

**Returns:**  
[String] The key requested.

</details>

<details>
<summary><code>function Generic:GetAsync(Key)</code></summary>

Same as GlobalDataStore::GetAsync. This function returns the value of the entry in the GlobalDataStore with the given key. If the key does not exist, returns nil. This function caches for about 4 seconds, so you cannot be sure that it returns the current value saved on the Roblox servers.

**Parameters:**
- `[String]`  
Key The key you wish to get data from.

**Returns:**  
[Tuple<Boolean, Variant>] Whether or not the attempt was successful and the value saved.

</details>

<details>
<summary><code>function Generic:SetAsync(Key, Value)</code></summary>

Same as GlobalDataStore::SetAsync. Sets the value of the key. This overwrites any existing data stored in the key. It's not recommended you use this when the previous data is important.

**Parameters:**
- `[String]`  
Key The key identifying the entry being retrieved from the DataStore.
- `[TableOrBooleanOrStringOrNumber]`  
Value The value of the entry in the DataStore with the given key.

**Returns:**  
[Tuple<Boolean, String>] Whether or not the attempt was successful and the possible error message if not successful.

</details>

<details>
<summary><code>function Generic:UpdateAsync(Key, Callback)</code></summary>

Same as GlobalDataStore::UpdateAsync. This function retrieves the value of a key from a DataStore and updates it with a new value. Since this function validates the data, it should be used in favor of SetAsync() when there's a chance that more than one server can edit the same data at the same time.

**Parameters:**
- `[String]`  
Key The key identifying the entry being retrieved from the DataStore.
- `[Function]`  
Callback A function which you need to provide. The function takes the key's old value as input and returns the new value.

**Returns:**  
[Tuple<Boolean, Variant>] Whether or not the attempt was successful and the value of the entry in the DataStore with the given key.

</details>

<details>
<summary><code>function Generic:RemoveAsync(Key)</code></summary>

Same as GlobalDataStore::RemoveAsync. This function removes the given key from the provided GlobalDataStore and returns the value that was associated with that key. If the key is not found in the DataStore, this function returns nil.

**Parameters:**
- `[String]`  
Key The key identifying the entry being retrieved from the DataStore.

**Returns:**  
[Tuple<Boolean, Variant>] Whether or not the attempt was successful and the value that was associated with the DataStore key, or nil if the key was not found.

</details>

<details>
<summary><code>function Generic:IncrementAsync(Key, Delta)</code></summary>

Same as GlobalDataStore::IncrementAsync. Increments the value for a particular key and returns the incremented value. Only works on values that are integers. Note that you can use OnUpdate() to execute a function every time the database updates the key's value, such as after calling this function.

**Parameters:**
- `[String]`  
Key The key identifying the entry being retrieved from the DataStore.
- `[OptionalInteger]`  
Delta The increment amount.

**Returns:**  
[Tuple<Boolean, Variant>] Whether or not the attempt was successful and the value of the entry in the DataStore with the given key.

</details>

<details>
<summary><code>function Generic:FixMissing(Key, DefaultData, OverwriteData)</code></summary>

This is like DataStore2's ::GetTable() function, where it'll add missing data from the default data.

**Parameters:**
- `[String]`  
Key The key identifying the entry being retrieved from the DataStore.
- `[NonNil]`  
DefaultData The default data you are using as a base.
- `[OptionalBoolean]`  
OverwriteData Determines whether or not you overwrite the previous data. Defaults to true.

**Returns:**  
[Tuple<Boolean, Table>] Whether or not the attempt was successful and the updated value of the entry in the DataStore with the given key.

</details>

<details>
<summary><code>function RbxWeb:GetOrdered(DataRoot)</code></summary>

Gets the methods of the given OrderedDataStore.

**Parameters:**
- `[OrderedDataStore]`  
DataRoot The OrderedDataStore you are using.

**Returns:**  
[RbxWebOrderedClass] The OrderedDataStore class with all the methods you can work with.

</details>

<details>
<summary><code>function Ordered:CollectData(Ascend)</code></summary>

Same as OrderedDataStore::GetSortedAsync, except for it goes through the DataStorePages for you.

**Parameters:**
- `[OptionalBoolean]`  
Ascend A boolean indicating whether the returned data pages are in ascending order. Defaults to false.

**Returns:**  
[Tuple<Boolean, Variant>] Whether or not the attempt was successful and the values of the DataStorePages.

</details>

<details>
<summary><code>function Ordered:GetKey(Data)</code></summary>

Gets the key. Recommended you pass a UserId for player data.

**Parameters:**
- `[Variant]`  
Data The data used for the key. It is suggested that you use a UserId when dealing with player data.

**Returns:**  
[String] The key requested.

</details>

<details>
<summary><code>function Ordered:GetAsync(Key)</code></summary>

Same as OrderedDataStore::GetAsync. This function returns the value of the entry in the OrderedDataStore with the given key. If the key does not exist, returns nil. This function caches for about 4 seconds, so you cannot be sure that it returns the current value saved on the Roblox servers.

**Parameters:**
- `[String]`  
Key The key you wish to get data from.

**Returns:**  
[Tuple<Boolean, Variant>] Whether or not the attempt was successful and the value saved.

</details>

<details>
<summary><code>function Ordered:SetAsync(Key, Value)</code></summary>

Same as OrderedDataStore::SetAsync. Sets the value of the key. This overwrites any existing data stored in the key. It's not recommended you use this when the previous data is important.

**Parameters:**
- `[String]`  
Key The key identifying the entry being retrieved from the DataStore.
- `[Variant]`  
Value The value of the entry in the DataStore with the given key.

**Returns:**  
[Tuple<Boolean, String>] Whether or not the attempt was successful and the possible error message if not successful.

</details>

<details>
<summary><code>function Ordered:UpdateAsync(Key, Callback)</code></summary>

Same as OrderedDataStore::UpdateAsync. This function retrieves the value of a key from a DataStore and updates it with a new value. Since this function validates the data, it should be used in favor of SetAsync() when there's a chance that more than one server can edit the same data at the same time.

**Parameters:**
- `[String]`  
Key The key identifying the entry being retrieved from the DataStore.
- `[Function]`  
Callback A function which you need to provide. The function takes the key's old value as input and returns the new value.

**Returns:**  
[Tuple<Boolean, Variant>] Whether or not the attempt was successful and the value of the entry in the DataStore with the given key.

</details>

<details>
<summary><code>function Ordered:RemoveAsync(Key)</code></summary>

Same as OrderedDataStore::RemoveAsync. This function removes the given key from the provided OrderedDataStore and returns the value that was associated with that key. If the key is not found in the DataStore, this function returns nil.

**Parameters:**
- `[String]`  
Key The key identifying the entry being retrieved from the DataStore.

**Returns:**  
[Tuple<Boolean, Variant>] Whether or not the attempt was successful and the value that was associated with the DataStore key, or nil if the key was not found.

</details>

<details>
<summary><code>function Ordered:IncrementAsync(Key, Delta)</code></summary>

Same as OrderedDataStore::IncrementAsync. Increments the value for a particular key and returns the incremented value. Only works on values that are integers. Note that you can use OnUpdate() to execute a function every time the database updates the key's value, such as after calling this function.

**Parameters:**
- `[String]`  
Key The key identifying the entry being retrieved from the DataStore.
- `[OptionalInteger]`  
Delta The increment amount.

**Returns:**  
[Tuple<Boolean, Variant>] Whether or not the attempt was successful and the value of the entry in the DataStore with the given key.

</details>

<details>
<summary><code>function Ordered:FixMissing(Key, DefaultData, OverwriteData)</code></summary>

This is like DataStore2's ::GetTable() function, where it'll add missing data from the default data.

**Parameters:**
- `[String]`  
Key The key identifying the entry being retrieved from the DataStore.
- `[NonNil]`  
DefaultData The default data you are using as a base.
- `[OptionalBoolean]`  
OverwriteData Determines whether or not you overwrite the previous data. Defaults to true.

**Returns:**  
[Tuple<Boolean, Table>] Whether or not the attempt was successful and the updated value of the entry in the DataStore with the given key.

</details>
