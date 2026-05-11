-- DataStoreHandler (ServerScriptService)
-- Saves and loads all player data: coins, rebirths, inventory,
-- discovered characters, VIP status, battle pass perks and index progress.

local DataStoreService  = game:GetService("DataStoreService")
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GD = require(ReplicatedStorage.Shared.GameData)

local dataStore    = DataStoreService:GetDataStore("PlayerData_v9")
local oldDataStore = DataStoreService:GetDataStore("PlayerData_v8")

local AUTOSAVE_INTERVAL = 120
local sessionData       = {}
local sessionStartTimes = {}

-- Price and passive income for every character.
-- Keeping this in one place makes rebalancing easier.
local ECONOMY_V3 = {
	["Yoo Jin-Ho"]    = {Price=30,        PassiveIncome=0.2},
	["Go Gun-Hee"]    = {Price=150,       PassiveIncome=0.6},
	["Cha Hae-In"]    = {Price=600,       PassiveIncome=2},
	["Sung Jin-Woo"]  = {Price=3000,      PassiveIncome=8},
	["Tank"]          = {Price=15000,     PassiveIncome=30},
	["Igris"]         = {Price=60000,     PassiveIncome=90},
	["Beru"]          = {Price=250000,    PassiveIncome=250},
	["Architect"]     = {Price=1500000,   PassiveIncome=800},
	["Magna Swing"]       = {Price=100,       PassiveIncome=0.5},
	["Luck Voltia"]       = {Price=400,       PassiveIncome=1.5},
	["Noelle Silva"]      = {Price=1800,      PassiveIncome=5},
	["Asta"]              = {Price=8000,      PassiveIncome=20},
	["Yuno"]              = {Price=40000,     PassiveIncome=70},
	["William Vangeance"] = {Price=180000,    PassiveIncome=220},
	["Yami Sukehiro"]     = {Price=700000,    PassiveIncome=600},
	["Julius Novachrono"] = {Price=3000000,   PassiveIncome=2000},
	["Lucifero"]          = {Price=12000000,  PassiveIncome=5000},
	["Leorio Paradinight"]    = {Price=300,       PassiveIncome=1.2},
	["Gon Freecss"]           = {Price=1200,      PassiveIncome=4},
	["Kurapika"]              = {Price=5000,      PassiveIncome=12},
	["Killua Zoldyck"]        = {Price=25000,     PassiveIncome=50},
	["Hisoka"]                = {Price=120000,    PassiveIncome=180},
	["Chrollo Lucifer"]       = {Price=500000,    PassiveIncome=550},
	["Isaac Netero"]          = {Price=2000000,   PassiveIncome=1500},
	["Killua Lightning Form"] = {Price=30000000,  PassiveIncome=12000},
	["Meruem"]                = {Price=50000000,  PassiveIncome=18000},
	["Rukia Kuchiki"]         = {Price=800,       PassiveIncome=3},
	["Ichigo Kurosaki"]       = {Price=3500,      PassiveIncome=10},
	["Renji Abarai"]          = {Price=15000,     PassiveIncome=30},
	["Grimmjow Jaegerjaquez"] = {Price=70000,     PassiveIncome=100},
	["Ulquiorra Cifer"]       = {Price=350000,    PassiveIncome=400},
	["Yhwach"]                = {Price=1500000,   PassiveIncome=1300},
	["Sosuke Aizen"]          = {Price=80000000,  PassiveIncome=25000},
	["Shota Aizawa"]      = {Price=2500,      PassiveIncome=8},
	["Izuku Midoriya"]    = {Price=10000,     PassiveIncome=25},
	["Katsuki Bakugo"]    = {Price=45000,     PassiveIncome=70},
	["Shoto Todoroki"]    = {Price=200000,    PassiveIncome=250},
	["Dabi"]              = {Price=900000,    PassiveIncome=900},
	["Tomura Shigaraki"]  = {Price=4000000,   PassiveIncome=3000},
	["All Might"]         = {Price=15000000,  PassiveIncome=8000},
	["All For One"]       = {Price=150000000, PassiveIncome=50000},
	["Armin Arlert"]         = {Price=7000,       PassiveIncome=20},
	["Eren Yeager"]          = {Price=30000,      PassiveIncome=60},
	["Mikasa Ackerman"]      = {Price=130000,     PassiveIncome=180},
	["Levi Ackerman"]        = {Price=600000,     PassiveIncome=600},
	["Female Titan"]         = {Price=2500000,    PassiveIncome=2000},
	["Armored Titan"]        = {Price=10000000,   PassiveIncome=7000},
	["Beast Titan"]          = {Price=40000000,   PassiveIncome=18000},
	["Colossal Titan"]       = {Price=150000000,  PassiveIncome=50000},
	["Attack Titan"]         = {Price=500000000,  PassiveIncome=120000},
	["Eren Founding Titan"]  = {Price=1500000000, PassiveIncome=350000},
	["Piccolo"]       = {Price=20000,       PassiveIncome=50},
	["Gohan"]         = {Price=80000,       PassiveIncome=150},
	["Goku"]          = {Price=350000,      PassiveIncome=450},
	["Vegeta"]        = {Price=1500000,     PassiveIncome=1500},
	["Frieza"]        = {Price=7000000,     PassiveIncome=5000},
	["Cell"]          = {Price=30000000,    PassiveIncome=15000},
	["Broly"]         = {Price=120000000,   PassiveIncome=45000},
	["Majin Buu"]     = {Price=500000000,   PassiveIncome=130000},
	["Goku SSJ GOD"]  = {Price=3000000000,  PassiveIncome=700000},
	["Sakura Haruno"]          = {Price=60000,        PassiveIncome=120},
	["Naruto Uzumaki"]         = {Price=250000,       PassiveIncome=350},
	["Gaara"]                  = {Price=1000000,      PassiveIncome=1000},
	["Kakashi Hatake"]         = {Price=5000000,      PassiveIncome=3500},
	["Orochimaru"]             = {Price=1200000,      PassiveIncome=1100},
	["Obito Uchiha"]           = {Price=6000000,      PassiveIncome=4000},
	["Sasuke Uchiha"]          = {Price=25000000,     PassiveIncome=12000},
	["Minato Namikaze"]        = {Price=100000000,    PassiveIncome=35000},
	["Pain"]                   = {Price=400000000,    PassiveIncome=100000},
	["Itachi Uchiha"]          = {Price=1500000000,   PassiveIncome=300000},
	["Naruto Baryon Mode"]     = {Price=8000000000,   PassiveIncome=1500000},
	["Madara Uchiha"]          = {Price=12000000000,  PassiveIncome=2000000},
	["Sasuke Uchiha Akatsuki"] = {Price=6000000000,   PassiveIncome=1200000},
	["Usopp"]                      = {Price=150000,        PassiveIncome=300},
	["Nami"]                       = {Price=600000,        PassiveIncome=800},
	["Crocodile"]                  = {Price=500000,        PassiveIncome=700},
	["Nico Robin"]                 = {Price=2500000,       PassiveIncome=2500},
	["Donquixote"]                 = {Price=3000000,       PassiveIncome=2800},
	["Sanji"]                      = {Price=12000000,      PassiveIncome=8000},
	["Enel"]                       = {Price=14000000,      PassiveIncome=9000},
	["Roronoa Zoro"]               = {Price=60000000,      PassiveIncome=25000},
	["Monkey D. Luffy"]            = {Price=70000000,      PassiveIncome=28000},
	["Portgas D. Ace"]             = {Price=250000000,     PassiveIncome=80000},
	["Trafalgar D. Law"]           = {Price=1000000000,    PassiveIncome=250000},
	["Boa Hancock"]                = {Price=4000000000,    PassiveIncome=700000},
	["Shanks"]                     = {Price=15000000000,   PassiveIncome=2000000},
	["Kaido"]                      = {Price=18000000000,   PassiveIncome=2500000},
	["Monkey D. Luffy Gear 5"]     = {Price=50000000000,   PassiveIncome=8000000},
	["Blackbeard"]                 = {Price=80000000000,   PassiveIncome=10000000},
}

-- Updates price and income on a saved character to match the current economy table.
-- Needed when a player's save was created before a balance change.
local function migrateCharData(charData)
	if not charData or not charData.CharacterName then return charData end
	local v3 = ECONOMY_V3[charData.CharacterName]
	if v3 then
		charData.Price         = v3.Price
		charData.PassiveIncome = v3.PassiveIncome
	end
	if not charData.Stars then charData.Stars = 1 end
	return charData
end

-- Shortcuts to shared game constants
local formatNumber        = GD.formatNumber
local RARITY_COLORS       = GD.RARITY_COLORS
local RARITY_DISPLAY      = GD.RARITY_DISPLAY
local SLOTS_PER_REBIRTH   = GD.SLOTS_PER_REBIRTH
local STORAGE_PER_REBIRTH = GD.STORAGE_PER_REBIRTH
local ANIME_BASE_COLORS   = GD.ANIME_BASE_COLORS

local function getCashMultiplier(rebirthLevel)
	return GD.getCashMultiplier(rebirthLevel)
end

local function getStarMultiplier(stars)
	return GD.getStarMultiplier(stars)
end

local INDEX_ANIME_NAMES = {
	"Solo Leveling", "Black Clover", "Hunter x Hunter", "Bleach",
	"My Hero Academia", "Attack on Titan", "Dragon Ball", "Naruto", "One Piece",
}


local function getPlayerBasePlateau(player)
	local playerNumber  = player:GetAttribute("SpawnerNumber") or 1
	local spawnerFolder = workspace:FindFirstChild("SpawnerPlayer" .. playerNumber)
	if not spawnerFolder then return nil end
	return spawnerFolder:FindFirstChild("BasePlateau" .. playerNumber)
end

local function ensureDiscoveredFolder(player)
	local folder = player:FindFirstChild("DiscoveredCharacters")
	if not folder then
		folder        = Instance.new("Folder")
		folder.Name   = "DiscoveredCharacters"
		folder.Parent = player
	end
	return folder
end

local function ensureInventory(player)
	local inventory = player:FindFirstChild("Inventory")
	if not inventory then
		inventory        = Instance.new("Folder")
		inventory.Name   = "Inventory"
		inventory.Parent = player
	end

	local storage = inventory:FindFirstChild("Storage")
	if not storage then
		storage        = Instance.new("Folder")
		storage.Name   = "Storage"
		storage.Parent = inventory
	end

	local invCount = inventory:FindFirstChild("InventoryCount")
	if not invCount then
		invCount        = Instance.new("IntValue")
		invCount.Name   = "InventoryCount"
		invCount.Value  = 0
		invCount.Parent = inventory
	end

	return inventory, storage, invCount
end

local function discoverCharacter(player, charName)
	if not charName or charName == "" then return end
	local folder = ensureDiscoveredFolder(player)
	if not folder:FindFirstChild(charName) then
		local tag     = Instance.new("BoolValue")
		tag.Name      = charName
		tag.Value     = true
		tag.Parent    = folder
	end
end


local function getSessionMinutes(player)
	local startTime = sessionStartTimes[player.UserId]
	if not startTime then return 0 end
	return math.floor((os.time() - startTime) / 60)
end

local function getTotalTimePlayed(player)
	local saved = player:GetAttribute("TimePlayedMinutes") or 0
	return saved + getSessionMinutes(player)
end

local function formatTimePlayed(totalMinutes)
	if totalMinutes < 60 then return totalMinutes .. " min" end
	local hours = math.floor(totalMinutes / 60)
	local mins  = totalMinutes % 60
	if mins == 0 then return hours .. "h" end
	return hours .. "h " .. mins .. "m"
end


local function serializeCharacter(char)
	local data = {
		CharacterName = char:GetAttribute("CharacterName") or "Unknown",
		Rarity        = char:GetAttribute("Rarity")        or "Common",
		PassiveIncome = char:GetAttribute("PassiveIncome") or 1,
		Price         = char:GetAttribute("Price")         or 10,
		Anime         = char:GetAttribute("Anime")         or "Unknown",
		Stars         = char:GetAttribute("Stars")         or 1,
		IsLocked      = char:GetAttribute("IsLocked")      == true,
		IsProtected   = char:GetAttribute("IsProtected")   == true,
		Size          = {char.Size.X,  char.Size.Y,  char.Size.Z},
		Color         = {char.Color.R, char.Color.G, char.Color.B},
		Material      = char.Material.Name,
		Transparency  = char.Transparency,
		Shape         = char.Shape.Name,
	}

	local mesh = char:FindFirstChildOfClass("SpecialMesh")
	if mesh then
		data.MeshId    = mesh.MeshId
		data.TextureId = mesh.TextureId
		data.MeshScale = {mesh.Scale.X, mesh.Scale.Y, mesh.Scale.Z}
		data.MeshType  = mesh.MeshType.Name
	end

	local decals = {}
	for _, d in pairs(char:GetChildren()) do
		if d:IsA("Decal") or d:IsA("Texture") then
			table.insert(decals, {
				ClassName = d.ClassName,
				Face      = d.Face.Name,
				Texture   = d.Texture,
			})
		end
	end
	if #decals > 0 then data.Decals = decals end

	return data
end


local function collectPlayerData(player)
	local data = {
		Version    = 4,
		Coins      = 0,
		Rebirths   = 0,
		TimePlayed = getTotalTimePlayed(player),

		SlotCharacters       = {},
		SlotPositions        = {},
		StorageCharacters    = {},
		DiscoveredCharacters = {},
		SeenCharacters       = {},

		SelectedBaseTheme = player:GetAttribute("SelectedBaseTheme"),

		IsVIP        = player:GetAttribute("IsVIP") == true,
		VIPNameColor = nil,

		HasBP_x2Luck       = player:GetAttribute("HasBP_x2Luck")       == true,
		HasBP_x2Coins      = player:GetAttribute("HasBP_x2Coins")      == true,
		HasBP_x2Speed      = player:GetAttribute("HasBP_x2Speed")      == true,
		HasBP_ExtraSlots   = player:GetAttribute("HasBP_ExtraSlots")   == true,
		HasBP_RebirthSave  = player:GetAttribute("HasBP_RebirthSave")  == true,
		HasBP_SaveAll      = player:GetAttribute("HasBP_SaveAll")      == true,
		HasPremiumSlapTool = player:GetAttribute("HasPremiumSlapTool") == true,

		IndexLuck      = player:GetAttribute("IndexLuck") or 0,
		IndexCollected = {},
	}

	for _, animeName in ipairs(INDEX_ANIME_NAMES) do
		if player:GetAttribute("IndexCollected_" .. animeName) == true then
			table.insert(data.IndexCollected, animeName)
		end
	end

	local vipColor = player:GetAttribute("VIPNameColor")
	if vipColor and typeof(vipColor) == "Color3" then
		data.VIPNameColor = {vipColor.R, vipColor.G, vipColor.B}
	end

	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local coins    = leaderstats:FindFirstChild("Coins")
		local rebirths = leaderstats:FindFirstChild("Rebirths")
		if coins    then data.Coins    = coins.Value    end
		if rebirths then data.Rebirths = rebirths.Value end
	end

	local basePlateau = getPlayerBasePlateau(player)
	if basePlateau then
		for _, slot in pairs(basePlateau:GetChildren()) do
			if slot:IsA("BasePart") and slot.Name:match("^Slot%d+$") then
				local slotNum = tonumber(slot.Name:match("%d+"))
				local relPos  = slot.Position - basePlateau.Position
				data.SlotPositions[tostring(slotNum)] = {relPos.X, relPos.Y, relPos.Z}

				for _, child in pairs(slot:GetChildren()) do
					if child.Name == "PlacedCharacter" and child:IsA("BasePart") then
						data.SlotCharacters[tostring(slotNum)] = serializeCharacter(child)
					end
				end
			end
		end
	end

	local inventory = player:FindFirstChild("Inventory")
	if inventory then
		local storage = inventory:FindFirstChild("Storage")
		if storage then
			for _, child in pairs(storage:GetChildren()) do
				if child:IsA("BasePart") then
					table.insert(data.StorageCharacters, serializeCharacter(child))
				end
			end
		end
	end

	local discoveredFolder = player:FindFirstChild("DiscoveredCharacters")
	if discoveredFolder then
		for _, child in pairs(discoveredFolder:GetChildren()) do
			table.insert(data.DiscoveredCharacters, child.Name)
		end
	end

	local seenFolder = player:FindFirstChild("SeenCharacters")
	if seenFolder then
		for _, child in pairs(seenFolder:GetChildren()) do
			table.insert(data.SeenCharacters, child.Name)
		end
	end

	if basePlateau then
		local pedestal = basePlateau:FindFirstChild("ShowcasePedestal")
		if pedestal then
			for _, child in pairs(pedestal:GetChildren()) do
				if child:IsA("BasePart") and child.Name == "ShowcaseCharacter" then
					data.ShowcaseCharacter = serializeCharacter(child)
				end
			end
		end
	end

	return data
end


local function savePlayerData(player)
	local data = collectPlayerData(player)
	local key  = "Player_" .. player.UserId

	-- Roll the session timer forward so the next interval starts fresh
	local currentSessionMinutes = getSessionMinutes(player)
	player:SetAttribute("TimePlayedMinutes",
		(player:GetAttribute("TimePlayedMinutes") or 0) + currentSessionMinutes)
	sessionStartTimes[player.UserId] = os.time()

	local success, err = pcall(function()
		dataStore:SetAsync(key, data)
	end)

	if success then
		print("[DataStore] Saved " .. player.Name
			.. " | time: "      .. formatTimePlayed(data.TimePlayed)
			.. " | vip: "       .. tostring(data.IsVIP)
			.. " | indexLuck: " .. data.IndexLuck)
	else
		warn("[DataStore] Failed to save " .. player.Name .. ": " .. tostring(err))
	end

	return success
end


local function loadPlayerData(player)
	local key  = "Player_" .. player.UserId
	local data = nil

	local success, err = pcall(function()
		data = dataStore:GetAsync(key)
	end)
	if not success then
		warn("[DataStore] Failed to load data for " .. player.Name .. ": " .. tostring(err))
	end

	-- No v9 data found, try migrating from v8
	if not data then
		local oldSuccess, _ = pcall(function()
			data = oldDataStore:GetAsync(key)
		end)

		if oldSuccess and data then
			print("[DataStore] Migrating " .. player.Name .. " from v8 to v9")

			if data.SlotCharacters then
				for slotNum, charData in pairs(data.SlotCharacters) do
					data.SlotCharacters[slotNum] = migrateCharData(charData)
				end
			end
			if data.StorageCharacters then
				for i, charData in ipairs(data.StorageCharacters) do
					data.StorageCharacters[i] = migrateCharData(charData)
				end
			end

			if not data.TimePlayed then data.TimePlayed = 0 end
			data.Version = 4

			pcall(function() dataStore:SetAsync(key, data) end)
			print("[DataStore] Migration done for " .. player.Name)
		end
	end

	-- Handle saves older than version 4
	if data and (not data.Version or data.Version < 4) then
		if data.SlotCharacters then
			for slotNum, charData in pairs(data.SlotCharacters) do
				data.SlotCharacters[slotNum] = migrateCharData(charData)
			end
		end
		if data.StorageCharacters then
			for i, charData in ipairs(data.StorageCharacters) do
				data.StorageCharacters[i] = migrateCharData(charData)
			end
		end
		if not data.TimePlayed then data.TimePlayed = 0 end
		data.Version = 4
	end

	if data and not data.TimePlayed then data.TimePlayed = 0 end

	return data
end


local function spawnCharacterFromData(charData, parent, position)
	charData = migrateCharData(charData)

	local char      = Instance.new("Part")
	char.Name       = "PlacedCharacter"
	char.Anchored   = true
	char.CanCollide = false

	char.Size = charData.Size
		and Vector3.new(charData.Size[1], charData.Size[2], charData.Size[3])
		or  Vector3.new(3, 3, 3)

	if charData.Color then
		char.Color = Color3.new(charData.Color[1], charData.Color[2], charData.Color[3])
	end
	if charData.Material then
		pcall(function() char.Material = Enum.Material[charData.Material] end)
	end
	if charData.Transparency then char.Transparency = charData.Transparency end
	if charData.Shape then
		pcall(function() char.Shape = Enum.PartType[charData.Shape] end)
	end

	if charData.MeshId and charData.MeshId ~= "" then
		local mesh  = Instance.new("SpecialMesh")
		mesh.MeshId = charData.MeshId
		if charData.TextureId then mesh.TextureId = charData.TextureId end
		if charData.MeshScale then
			mesh.Scale = Vector3.new(charData.MeshScale[1], charData.MeshScale[2], charData.MeshScale[3])
		end
		if charData.MeshType then
			pcall(function() mesh.MeshType = Enum.MeshType[charData.MeshType] end)
		end
		mesh.Parent = char
	end

	if charData.Decals then
		for _, decalData in pairs(charData.Decals) do
			local decal   = Instance.new(decalData.ClassName)
			pcall(function() decal.Face = Enum.NormalId[decalData.Face] end)
			decal.Texture = decalData.Texture
			decal.Parent  = char
		end
	end

	local stars        = charData.Stars or 1
	local starMult     = getStarMultiplier(stars)
	local baseIncome   = charData.PassiveIncome or 1
	local actualIncome = baseIncome * starMult

	char:SetAttribute("CharacterName",     charData.CharacterName)
	char:SetAttribute("Rarity",            charData.Rarity)
	char:SetAttribute("BasePassiveIncome", baseIncome)
	char:SetAttribute("PassiveIncome",     actualIncome)
	char:SetAttribute("Price",             charData.Price)
	char:SetAttribute("Anime",             charData.Anime or "Unknown")
	char:SetAttribute("Stars",             stars)
	char:SetAttribute("IsLocked",          charData.IsLocked)
	char:SetAttribute("IsProtected",       charData.IsProtected == true)
	char:SetAttribute("InInventory",       parent.Name == "Storage")

	if position then char.Position = position end

	-- Name tag shown above the character in-world
	local rarityColor   = RARITY_COLORS[charData.Rarity] or Color3.fromRGB(180, 180, 180)
	local rarityDisplay = RARITY_DISPLAY[charData.Rarity] or "Common"
	local rd = rarityDisplay == "Ultra-Legendary" and "Ultra-L." or rarityDisplay

	local bbg          = Instance.new("BillboardGui")
	bbg.Name           = "NameTag"
	bbg.Adornee        = char
	bbg.Size           = UDim2.new(0, 200, 0, 110)
	bbg.StudsOffset    = Vector3.new(0, 5, 0)
	bbg.LightInfluence = 0
	bbg.AlwaysOnTop    = false
	bbg.MaxDistance    = 120
	bbg.Parent         = char

	local card                  = Instance.new("Frame", bbg)
	card.Size                   = UDim2.new(1, 0, 1, 0)
	card.BackgroundColor3       = Color3.fromRGB(10, 10, 14)
	card.BackgroundTransparency = 0.08
	card.BorderSizePixel        = 0
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)

	local stroke        = Instance.new("UIStroke", card)
	stroke.Color        = rarityColor
	stroke.Thickness    = 1.8
	stroke.Transparency = 0.15

	local pad         = Instance.new("UIPadding", card)
	pad.PaddingLeft   = UDim.new(0, 9)
	pad.PaddingRight  = UDim.new(0, 9)
	pad.PaddingTop    = UDim.new(0, 7)
	pad.PaddingBottom = UDim.new(0, 7)

	local pill                  = Instance.new("Frame", card)
	pill.Size                   = UDim2.new(0, 0, 0, 17)
	pill.AutomaticSize          = Enum.AutomaticSize.X
	pill.BackgroundColor3       = rarityColor
	pill.BackgroundTransparency = 0.3
	pill.BorderSizePixel        = 0
	Instance.new("UICorner", pill).CornerRadius = UDim.new(1, 0)

	local pillPad        = Instance.new("UIPadding", pill)
	pillPad.PaddingLeft  = UDim.new(0, 6)
	pillPad.PaddingRight = UDim.new(0, 6)

	local pillText                  = Instance.new("TextLabel", pill)
	pillText.Size                   = UDim2.new(0, 0, 1, 0)
	pillText.AutomaticSize          = Enum.AutomaticSize.X
	pillText.BackgroundTransparency = 1
	pillText.Text                   = rd
	pillText.Font                   = Enum.Font.GothamBold
	pillText.TextSize               = 10
	pillText.TextColor3             = Color3.fromRGB(255, 255, 255)
	pillText.TextStrokeTransparency = 0.4

	if stars > 1 then
		local starColors = {
			[2] = Color3.fromRGB(220, 220, 220),
			[3] = Color3.fromRGB(255, 215, 0),
			[4] = Color3.fromRGB(255, 140, 0),
			[5] = Color3.fromRGB(255, 50,  50),
		}
		local starColor = starColors[math.min(stars, 5)] or Color3.fromRGB(255, 215, 0)
		local starSize  = 8 + (stars - 1)

		local starLabel                  = Instance.new("TextLabel", pill)
		starLabel.Size                   = UDim2.new(0, 0, 1, 0)
		starLabel.AutomaticSize          = Enum.AutomaticSize.X
		starLabel.Position               = UDim2.new(1, 2, 0, 0)
		starLabel.BackgroundTransparency = 1
		starLabel.Text                   = " " .. string.rep("*", stars)
		starLabel.Font                   = Enum.Font.GothamBold
		starLabel.TextSize               = starSize
		starLabel.TextColor3             = starColor
	end

	local nameL                  = Instance.new("TextLabel", card)
	nameL.Size                   = UDim2.new(1, 0, 0, 24)
	nameL.Position               = UDim2.new(0, 0, 0, 20)
	nameL.BackgroundTransparency = 1
	nameL.Text                   = charData.CharacterName
	nameL.Font                   = Enum.Font.GothamBold
	nameL.TextSize               = 17
	nameL.TextScaled             = false
	nameL.TextColor3             = Color3.fromRGB(240, 240, 245)
	nameL.TextStrokeTransparency = 0.5
	nameL.TextXAlignment         = Enum.TextXAlignment.Left

	local ANIME_COLORS_DS = {
		["Solo Leveling"]    = Color3.fromRGB(108, 59,  245),
		["Black Clover"]     = Color3.fromRGB(26,  188, 156),
		["Hunter x Hunter"]  = Color3.fromRGB(76,  175, 80),
		["Bleach"]           = Color3.fromRGB(245, 166, 35),
		["My Hero Academia"] = Color3.fromRGB(46,  204, 113),
		["Attack on Titan"]  = Color3.fromRGB(107, 142, 35),
		["Dragon Ball"]      = Color3.fromRGB(255, 140, 0),
		["Naruto"]           = Color3.fromRGB(255, 107, 53),
		["One Piece"]        = Color3.fromRGB(231, 76,  60),
	}

	local animeL                  = Instance.new("TextLabel", card)
	animeL.Size                   = UDim2.new(1, 0, 0, 13)
	animeL.Position               = UDim2.new(0, 0, 0, 46)
	animeL.BackgroundTransparency = 1
	animeL.Text                   = charData.Anime or ""
	animeL.Font                   = Enum.Font.Gotham
	animeL.TextSize               = 13
	animeL.TextColor3             = ANIME_COLORS_DS[charData.Anime or ""] or Color3.fromRGB(160, 160, 190)
	animeL.TextStrokeTransparency = 0.5
	animeL.TextXAlignment         = Enum.TextXAlignment.Left

	local sep                  = Instance.new("Frame", card)
	sep.Size                   = UDim2.new(1, 0, 0, 1)
	sep.Position               = UDim2.new(0, 0, 0, 62)
	sep.BackgroundColor3       = rarityColor
	sep.BackgroundTransparency = 0.65
	sep.BorderSizePixel        = 0

	local incText = "+" .. formatNumber(actualIncome) .. "/s"
	if stars > 1 then
		incText = incText .. " (x" .. string.format("%.1f", starMult) .. ")"
	end

	local incL                  = Instance.new("TextLabel", card)
	incL.Size                   = UDim2.new(1, 0, 0, 16)
	incL.Position               = UDim2.new(0, 0, 0, 67)
	incL.BackgroundTransparency = 1
	incL.Text                   = incText
	incL.Font                   = Enum.Font.GothamBold
	incL.TextSize               = 12
	incL.TextColor3             = Color3.fromRGB(100, 255, 120)
	incL.TextStrokeTransparency = 0.4
	incL.TextXAlignment         = Enum.TextXAlignment.Left

	-- Highlight effect based on rarity
	local rarityHighlights = {
		Secret    = {fill=Color3.fromRGB(255,255,0),   fillT=0.3, outline=Color3.fromRGB(255,0,0),    outlineT=0},
		Celestial = {fill=Color3.fromRGB(255,255,100), fillT=0.5, outline=Color3.fromRGB(255,200,0),  outlineT=0.2},
		Ascendent = {fill=Color3.fromRGB(255,255,255), fillT=0.6, outline=Color3.fromRGB(200,200,255),outlineT=0.3},
		Mythic    = {fill=Color3.fromRGB(255,0,100),   fillT=0.7, outline=Color3.fromRGB(255,50,150), outlineT=0.4},
	}
	local hl = rarityHighlights[charData.Rarity]
	if hl then
		local h             = Instance.new("Highlight")
		h.FillColor         = hl.fill
		h.FillTransparency  = hl.fillT
		h.OutlineColor      = hl.outline
		h.OutlineTransparency = hl.outlineT
		h.Parent            = char
	end

	if stars >= 4 then
		local glow      = Instance.new("PointLight")
		glow.Name       = "StarGlow"
		glow.Color      = Color3.fromRGB(255, 215, 0)
		glow.Brightness = 0.5 + (stars - 3) * 0.3
		glow.Range      = 6 + stars
		glow.Parent     = char
	end

	char.Parent = parent
	return char
end


local function restorePlayer(player, data)
	if not data then return end

	local leaderstats = player:WaitForChild("leaderstats", 10)
	if not leaderstats then return end

	local coins = leaderstats:FindFirstChild("Coins")
	if coins and data.Coins and data.Coins > 0 then
		coins.Value = data.Coins
	end

	local rebirths = leaderstats:FindFirstChild("Rebirths")
	if rebirths and data.Rebirths then
		rebirths.Value = data.Rebirths
		player:SetAttribute("CashMultiplier",  getCashMultiplier(data.Rebirths))
		player:SetAttribute("StorageCapacity", STORAGE_PER_REBIRTH[data.Rebirths] or 4)
		player:SetAttribute("SlotCount",       SLOTS_PER_REBIRTH[data.Rebirths]   or 5)
	end

	player:SetAttribute("TimePlayedMinutes", data.TimePlayed or 0)

	if data.SelectedBaseTheme ~= nil then
		player:SetAttribute("SelectedBaseTheme", data.SelectedBaseTheme)
	end

	if data.IsVIP then
		player:SetAttribute("IsVIP", true)
		if data.VIPNameColor then
			player:SetAttribute("VIPNameColor",
				Color3.new(data.VIPNameColor[1], data.VIPNameColor[2], data.VIPNameColor[3]))
		else
			player:SetAttribute("VIPNameColor", Color3.fromRGB(255, 215, 0))
		end
	end

	local bpPerks = {
		"HasBP_x2Luck", "HasBP_x2Coins", "HasBP_x2Speed",
		"HasBP_ExtraSlots", "HasBP_RebirthSave", "HasBP_SaveAll", "HasPremiumSlapTool",
	}
	for _, perk in ipairs(bpPerks) do
		if data[perk] then player:SetAttribute(perk, true) end
	end

	if data.IndexLuck then
		player:SetAttribute("IndexLuck", data.IndexLuck)
	end
	if data.IndexCollected then
		for _, animeName in ipairs(data.IndexCollected) do
			player:SetAttribute("IndexCollected_" .. animeName, true)
		end
	end

	-- Apply plateau color after the base has had time to load
	task.delay(2, function()
		local bp = getPlayerBasePlateau(player)
		if bp then
			local colorLevel = player:GetAttribute("SelectedBaseTheme") or (data.Rebirths or 0)
			bp.Color    = ANIME_BASE_COLORS[colorLevel] or Color3.fromRGB(108, 59, 245)
			bp.Material = Enum.Material.SmoothPlastic
		end
	end)

	task.wait(0.5)

	local basePlateau = getPlayerBasePlateau(player)
	if not basePlateau then
		warn("[DataStore] BasePlateau not found for " .. player.Name)
		return
	end

	local _, storage, invCount = ensureInventory(player)

	if data.SlotPositions then
		for slotNumStr, relPosData in pairs(data.SlotPositions) do
			local slot = basePlateau:FindFirstChild("Slot" .. tonumber(slotNumStr))
			if slot and slot:IsA("BasePart") then
				slot.Position = basePlateau.Position
					+ Vector3.new(relPosData[1], relPosData[2], relPosData[3])
			end
		end
	end

	if data.SlotCharacters then
		for slotNumStr, charData in pairs(data.SlotCharacters) do
			local slot = basePlateau:FindFirstChild("Slot" .. tonumber(slotNumStr))
			if slot then
				for _, child in pairs(slot:GetChildren()) do
					if child.Name == "PlacedCharacter" then child:Destroy() end
				end
				local restored = spawnCharacterFromData(charData, slot, slot.Position + Vector3.new(0, 2, 0))
				slot:SetAttribute("Occupied", true)
				if restored then discoverCharacter(player, charData.CharacterName) end
			end
		end
	end

	if data.StorageCharacters and #data.StorageCharacters > 0 then
		for _, charData in pairs(data.StorageCharacters) do
			local char = spawnCharacterFromData(charData, storage, Vector3.new(0, -200, 0))
			if char then
				invCount.Value = invCount.Value + 1
				discoverCharacter(player, charData.CharacterName)
			end
		end
	end

	if data.DiscoveredCharacters then
		for _, charName in pairs(data.DiscoveredCharacters) do
			discoverCharacter(player, charName)
		end
	end

	if data.SeenCharacters then
		local seenFolder = player:FindFirstChild("SeenCharacters")
		if not seenFolder then
			seenFolder        = Instance.new("Folder")
			seenFolder.Name   = "SeenCharacters"
			seenFolder.Parent = player
		end
		for _, charName in pairs(data.SeenCharacters) do
			if not seenFolder:FindFirstChild(charName) then
				local tag     = Instance.new("BoolValue")
				tag.Name      = charName
				tag.Value     = true
				tag.Parent    = seenFolder
			end
		end
	end

	if data.ShowcaseCharacter then
		task.delay(3, function()
			local bp = getPlayerBasePlateau(player)
			if not bp then return end
			local pedestal = bp:FindFirstChild("ShowcasePedestal")
			if not pedestal then return end

			for _, child in pairs(pedestal:GetChildren()) do
				if child:IsA("BasePart") and child.Name == "ShowcaseCharacter" then
					child:Destroy()
				end
			end

			local charData = migrateCharData(data.ShowcaseCharacter)
			local char     = spawnCharacterFromData(charData, pedestal, pedestal.Position + Vector3.new(0, 3, 0))
			if char then
				char.Name = "ShowcaseCharacter"
				char:SetAttribute("IsShowcase",  true)
				char:SetAttribute("InInventory", false)

				local h               = Instance.new("Highlight")
				h.Name                = "ShowcaseGlow"
				h.FillColor           = Color3.fromRGB(0, 255, 200)
				h.FillTransparency    = 0.85
				h.OutlineColor        = Color3.fromRGB(0, 200, 150)
				h.OutlineTransparency = 0.3
				h.Parent              = char
			end
		end)
	end

	local collectedCount = data.IndexCollected and #data.IndexCollected or 0
	print("[DataStore] Restored " .. player.Name
		.. " | coins: "      .. formatNumber(data.Coins or 0)
		.. " | rebirths: "   .. (data.Rebirths or 0)
		.. " | multiplier: " .. getCashMultiplier(data.Rebirths or 0) .. "x"
		.. " | vip: "        .. tostring(data.IsVIP or false)
		.. " | indexLuck: "  .. (data.IndexLuck or 0)
		.. " (" .. collectedCount .. " collected)"
		.. " | time: "       .. formatTimePlayed(data.TimePlayed or 0))
end


Players.PlayerAdded:Connect(function(player)
	sessionStartTimes[player.UserId] = os.time()
	task.wait(0.5)

	local data = loadPlayerData(player)

	local hasData = data and (
		(data.Coins or 0) > 0
		or (data.SlotCharacters       and next(data.SlotCharacters))
		or (data.StorageCharacters    and #data.StorageCharacters > 0)
		or (data.DiscoveredCharacters and #data.DiscoveredCharacters > 0)
		or (data.Rebirths             and data.Rebirths > 0)
		or (data.TimePlayed           and data.TimePlayed > 0)
		or data.IsVIP
		or data.HasBP_x2Luck or data.HasBP_x2Coins or data.HasBP_x2Speed
		or data.HasBP_ExtraSlots or data.HasBP_RebirthSave or data.HasBP_SaveAll
		or (data.IndexLuck            and data.IndexLuck > 0)
		or (data.IndexCollected       and #data.IndexCollected > 0)
	)

	if hasData then
		restorePlayer(player, data)
	else
		player:SetAttribute("TimePlayedMinutes", 0)
		print("[DataStore] New player: " .. player.Name)
	end

	sessionData[player.UserId] = true
end)

Players.PlayerRemoving:Connect(function(player)
	local sessionMins = getSessionMinutes(player)
	player:SetAttribute("TimePlayedMinutes",
		(player:GetAttribute("TimePlayedMinutes") or 0) + sessionMins)
	sessionStartTimes[player.UserId] = nil
	savePlayerData(player)
	sessionData[player.UserId] = nil
end)


task.spawn(function()
	while true do
		task.wait(AUTOSAVE_INTERVAL)
		for _, player in pairs(Players:GetPlayers()) do
			task.spawn(function() savePlayerData(player) end)
		end
	end
end)

game:BindToClose(function()
	for _, player in pairs(Players:GetPlayers()) do
		local sessionMins = getSessionMinutes(player)
		player:SetAttribute("TimePlayedMinutes",
			(player:GetAttribute("TimePlayedMinutes") or 0) + sessionMins)
		savePlayerData(player)
	end
end)

print("[DataStore] Handler loaded")

-- GrantSpecialCharacter is fired by ShopHandler when a player buys
-- a character directly instead of rolling for it.
local grantSpecialChar  = Instance.new("BindableEvent")
grantSpecialChar.Name   = "GrantSpecialCharacter"
grantSpecialChar.Parent = game:GetService("ServerScriptService")

grantSpecialChar.Event:Connect(function(player, charData)
	if not player or not player.Parent then return end

	local maxStorage    = GD.STORAGE_PER_REBIRTH[player:GetAttribute("RebirthCount") or 0] or 4
	local _, storage, _ = ensureInventory(player)
	if not storage then return end

	if #storage:GetChildren() >= maxStorage then
		local ne = ReplicatedStorage:FindFirstChild("NotifyEvent")
		if ne then ne:FireClient(player, "Storage is full! Free up space first.", "warning") end
		return
	end

	local char = spawnCharacterFromData(charData, storage, Vector3.new(0, -500, 0))
	char.Parent = storage
	discoverCharacter(player, charData.CharacterName)
	savePlayerData(player)
end)