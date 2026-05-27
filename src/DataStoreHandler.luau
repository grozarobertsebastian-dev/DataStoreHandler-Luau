-- saves and loads - coins, rebirths, inventory,
-- saves progress, purchases, index...

local DataStoreService  = game:GetService("DataStoreService")
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GD = require(ReplicatedStorage.Shared.GameData)

local data_store     = DataStoreService:GetDataStore("PlayerData_v9")
local old_data_store = DataStoreService:GetDataStore("PlayerData_v8")

local AUTOSAVE_INTERVAL = 120
local session_data      = {}
local session_start_times = {}

-- price and passive income for every character.
-- keeping this in one place makes rebalancing easier.

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

-- updates price and income on a saved character to match current economy table.
-- needed when a players save was created before a balance change.

local function migrate_char_data(cd)
	if not cd or not cd.CharacterName then return cd end
	local v3 = ECONOMY_V3[cd.CharacterName]
	if v3 then
		cd.Price         = v3.Price
		cd.PassiveIncome = v3.PassiveIncome
	end
	if not cd.Stars then cd.Stars = 1 end
	return cd
end

local formatNumber        = GD.formatNumber
local RARITY_COLORS       = GD.RARITY_COLORS
local RARITY_DISPLAY      = GD.RARITY_DISPLAY
local SLOTS_PER_REBIRTH   = GD.SLOTS_PER_REBIRTH
local STORAGE_PER_REBIRTH = GD.STORAGE_PER_REBIRTH
local ANIME_BASE_COLORS   = GD.ANIME_BASE_COLORS

local function get_cash_multiplier(level) return GD.getCashMultiplier(level) end
local function get_star_multiplier(stars) return GD.getStarMultiplier(stars) end

local INDEX_ANIME_NAMES = {
	"Solo Leveling", "Black Clover", "Hunter x Hunter", "Bleach",
	"My Hero Academia", "Attack on Titan", "Dragon Ball", "Naruto", "One Piece",
}

-- player helpers

local function get_base_plateau(player)
	local pn     = player:GetAttribute("SpawnerNumber") or 1
	local folder = workspace:FindFirstChild("SpawnerPlayer" .. pn)
	if not folder then return nil end
	return folder:FindFirstChild("BasePlateau" .. pn)
end

local function ensure_discovered(player)
	local folder = player:FindFirstChild("DiscoveredCharacters")
	if not folder then
		folder        = Instance.new("Folder")
		folder.Name   = "DiscoveredCharacters"
		folder.Parent = player
	end
	return folder
end

local function ensure_inventory(player)
	local inv = player:FindFirstChild("Inventory")
	if not inv then
		inv        = Instance.new("Folder")
		inv.Name   = "Inventory"
		inv.Parent = player
	end
	local stor = inv:FindFirstChild("Storage")
	if not stor then
		stor        = Instance.new("Folder")
		stor.Name   = "Storage"
		stor.Parent = inv
	end
	local ic = inv:FindFirstChild("InventoryCount")
	if not ic then
		ic        = Instance.new("IntValue")
		ic.Name   = "InventoryCount"
		ic.Value  = 0
		ic.Parent = inv
	end
	return inv, stor, ic
end

local function discover_character(player, char_name)
	if not char_name or char_name == "" then return end
	local folder = ensure_discovered(player)
	if not folder:FindFirstChild(char_name) then
		local tag     = Instance.new("BoolValue")
		tag.Name      = char_name
		tag.Value     = true
		tag.Parent    = folder
	end
end

-- session time helpers

local function get_session_minutes(player)
	local start = session_start_times[player.UserId]
	if not start then return 0 end
	return math.floor((os.time() - start) / 60)
end

local function get_total_time_played(player)
	return (player:GetAttribute("TimePlayedMinutes") or 0) + get_session_minutes(player)
end

local function format_time_played(mins)
	if mins < 60 then return mins .. " min" end
	local h = math.floor(mins / 60)
	local m = mins % 60
	if m == 0 then return h .. "h" end
	return h .. "h " .. m .. "m"
end

-- character serialization

local function serialize_character(char)
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
			table.insert(decals, {ClassName=d.ClassName, Face=d.Face.Name, Texture=d.Texture})
		end
	end
	if #decals > 0 then data.Decals = decals end
	return data
end

-- collect all player data for saving

local function collect_player_data(player)
	local data = {
		Version    = 4,
		Coins      = 0,
		Rebirths   = 0,
		TimePlayed = get_total_time_played(player),

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
	for _, anime in ipairs(INDEX_ANIME_NAMES) do
		if player:GetAttribute("IndexCollected_" .. anime) == true then
			table.insert(data.IndexCollected, anime)
		end
	end
	local vip_color = player:GetAttribute("VIPNameColor")
	if vip_color and typeof(vip_color) == "Color3" then
		data.VIPNameColor = {vip_color.R, vip_color.G, vip_color.B}
	end
	local ls = player:FindFirstChild("leaderstats")
	if ls then
		local coins    = ls:FindFirstChild("Coins")
		local rebirths = ls:FindFirstChild("Rebirths")
		if coins    then data.Coins    = coins.Value    end
		if rebirths then data.Rebirths = rebirths.Value end
	end
	local bp = get_base_plateau(player)
	if bp then
		for _, slot in pairs(bp:GetChildren()) do
			if slot:IsA("BasePart") and slot.Name:match("^Slot%d+$") then
				local num     = tonumber(slot.Name:match("%d+"))
				local rel_pos = slot.Position - bp.Position
				data.SlotPositions[tostring(num)] = {rel_pos.X, rel_pos.Y, rel_pos.Z}
				for _, child in pairs(slot:GetChildren()) do
					if child.Name == "PlacedCharacter" and child:IsA("BasePart") then
						data.SlotCharacters[tostring(num)] = serialize_character(child)
					end
				end
			end
		end
	end
	local inv = player:FindFirstChild("Inventory")
	if inv then
		local stor = inv:FindFirstChild("Storage")
		if stor then
			for _, child in pairs(stor:GetChildren()) do
				if child:IsA("BasePart") then
					table.insert(data.StorageCharacters, serialize_character(child))
				end
			end
		end
	end
	local discovered = player:FindFirstChild("DiscoveredCharacters")
	if discovered then
		for _, child in pairs(discovered:GetChildren()) do
			table.insert(data.DiscoveredCharacters, child.Name)
		end
	end
	local seen = player:FindFirstChild("SeenCharacters")
	if seen then
		for _, child in pairs(seen:GetChildren()) do
			table.insert(data.SeenCharacters, child.Name)
		end
	end
	if bp then
		local pedestal = bp:FindFirstChild("ShowcasePedestal")
		if pedestal then
			for _, child in pairs(pedestal:GetChildren()) do
				if child:IsA("BasePart") and child.Name == "ShowcaseCharacter" then
					data.ShowcaseCharacter = serialize_character(child)
				end
			end
		end
	end
	return data
end

-- save player data

local function save_player_data(player)
	local data = collect_player_data(player)
	local key  = "Player_" .. player.UserId
	local session_mins = get_session_minutes(player)
	player:SetAttribute("TimePlayedMinutes",
		(player:GetAttribute("TimePlayedMinutes") or 0) + session_mins)
	session_start_times[player.UserId] = os.time()
	local ok, err = pcall(function()
		data_store:SetAsync(key, data)
	end)
	if ok then
		print("[DataStore] Saved " .. player.Name
			.. " | time: "      .. format_time_played(data.TimePlayed)
			.. " | vip: "       .. tostring(data.IsVIP)
			.. " | indexLuck: " .. data.IndexLuck)
	else
		warn("[DataStore] Failed to save " .. player.Name .. ": " .. tostring(err))
	end
	return ok
end

-- load player data

local function load_player_data(player)
	local key  = "Player_" .. player.UserId
	local data = nil
	local ok, err = pcall(function()
		data = data_store:GetAsync(key)
	end)
	if not ok then
		warn("[DataStore] Failed to load data for " .. player.Name .. ": " .. tostring(err))
	end
	if not data then
		local old_ok, _ = pcall(function()
			data = old_data_store:GetAsync(key)
		end)
		if old_ok and data then
			print("[DataStore] Migrating " .. player.Name .. " from v8 to v9")
			if data.SlotCharacters then
				for k, cd in pairs(data.SlotCharacters) do
					data.SlotCharacters[k] = migrate_char_data(cd)
				end
			end
			if data.StorageCharacters then
				for i, cd in ipairs(data.StorageCharacters) do
					data.StorageCharacters[i] = migrate_char_data(cd)
				end
			end
			if not data.TimePlayed then data.TimePlayed = 0 end
			data.Version = 4
			pcall(function() data_store:SetAsync(key, data) end)
			print("[DataStore] Migration done for " .. player.Name)
		end
	end
	if data and (not data.Version or data.Version < 4) then
		if data.SlotCharacters then
			for k, cd in pairs(data.SlotCharacters) do
				data.SlotCharacters[k] = migrate_char_data(cd)
			end
		end
		if data.StorageCharacters then
			for i, cd in ipairs(data.StorageCharacters) do
				data.StorageCharacters[i] = migrate_char_data(cd)
			end
		end
		if not data.TimePlayed then data.TimePlayed = 0 end
		data.Version = 4
	end
	if data and not data.TimePlayed then data.TimePlayed = 0 end
	return data
end

-- spawn a character from saved data

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

local function spawn_character_from_data(cd, parent, position)
	cd = migrate_char_data(cd)
	local char      = Instance.new("Part")
	char.Name       = "PlacedCharacter"
	char.Anchored   = true
	char.CanCollide = false
	char.Size = cd.Size and Vector3.new(cd.Size[1], cd.Size[2], cd.Size[3]) or Vector3.new(3, 3, 3)
	if cd.Color       then char.Color = Color3.new(cd.Color[1], cd.Color[2], cd.Color[3]) end
	if cd.Material    then pcall(function() char.Material = Enum.Material[cd.Material]  end) end
	if cd.Transparency then char.Transparency = cd.Transparency end
	if cd.Shape       then pcall(function() char.Shape    = Enum.PartType[cd.Shape]      end) end
	if cd.MeshId and cd.MeshId ~= "" then
		local mesh  = Instance.new("SpecialMesh")
		mesh.MeshId = cd.MeshId
		if cd.TextureId then mesh.TextureId = cd.TextureId end
		if cd.MeshScale then mesh.Scale = Vector3.new(cd.MeshScale[1], cd.MeshScale[2], cd.MeshScale[3]) end
		if cd.MeshType  then pcall(function() mesh.MeshType = Enum.MeshType[cd.MeshType] end) end
		mesh.Parent = char
	end
	if cd.Decals then
		for _, d in pairs(cd.Decals) do
			local decal   = Instance.new(d.ClassName)
			pcall(function() decal.Face = Enum.NormalId[d.Face] end)
			decal.Texture = d.Texture
			decal.Parent  = char
		end
	end
	local stars        = cd.Stars or 1
	local star_mult    = get_star_multiplier(stars)
	local base_income  = cd.PassiveIncome or 1
	local actual_income = base_income * star_mult
	char:SetAttribute("CharacterName",     cd.CharacterName)
	char:SetAttribute("Rarity",            cd.Rarity)
	char:SetAttribute("BasePassiveIncome", base_income)
	char:SetAttribute("PassiveIncome",     actual_income)
	char:SetAttribute("Price",             cd.Price)
	char:SetAttribute("Anime",             cd.Anime or "Unknown")
	char:SetAttribute("Stars",             stars)
	char:SetAttribute("IsLocked",          cd.IsLocked)
	char:SetAttribute("IsProtected",       cd.IsProtected == true)
	char:SetAttribute("InInventory",       parent.Name == "Storage")
	if position then char.Position = position end

	-- nametag
	local rarity_color   = RARITY_COLORS[cd.Rarity] or Color3.fromRGB(180, 180, 180)
	local rarity_display = RARITY_DISPLAY[cd.Rarity] or "Common"
	local rd = rarity_display == "Ultra-Legendary" and "Ultra-L." or rarity_display

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
	stroke.Color        = rarity_color
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
	pill.BackgroundColor3       = rarity_color
	pill.BackgroundTransparency = 0.3
	pill.BorderSizePixel        = 0
	Instance.new("UICorner", pill).CornerRadius = UDim.new(1, 0)

	local pill_pad        = Instance.new("UIPadding", pill)
	pill_pad.PaddingLeft  = UDim.new(0, 6)
	pill_pad.PaddingRight = UDim.new(0, 6)

	local pill_text                  = Instance.new("TextLabel", pill)
	pill_text.Size                   = UDim2.new(0, 0, 1, 0)
	pill_text.AutomaticSize          = Enum.AutomaticSize.X
	pill_text.BackgroundTransparency = 1
	pill_text.Text                   = rd
	pill_text.Font                   = Enum.Font.GothamBold
	pill_text.TextSize               = 10
	pill_text.TextColor3             = Color3.fromRGB(255, 255, 255)
	pill_text.TextStrokeTransparency = 0.4

	if stars > 1 then
		local star_colors = {
			[2] = Color3.fromRGB(220, 220, 220),
			[3] = Color3.fromRGB(255, 215, 0),
			[4] = Color3.fromRGB(255, 140, 0),
			[5] = Color3.fromRGB(255, 50,  50),
		}
		local star_color = star_colors[math.min(stars, 5)] or Color3.fromRGB(255, 215, 0)
		local star_size  = 8 + (stars - 1)
		local star_label                  = Instance.new("TextLabel", pill)
		star_label.Size                   = UDim2.new(0, 0, 1, 0)
		star_label.AutomaticSize          = Enum.AutomaticSize.X
		star_label.Position               = UDim2.new(1, 2, 0, 0)
		star_label.BackgroundTransparency = 1
		star_label.Text                   = " " .. string.rep("*", stars)
		star_label.Font                   = Enum.Font.GothamBold
		star_label.TextSize               = star_size
		star_label.TextColor3             = star_color
	end

	local name_l                  = Instance.new("TextLabel", card)
	name_l.Size                   = UDim2.new(1, 0, 0, 24)
	name_l.Position               = UDim2.new(0, 0, 0, 20)
	name_l.BackgroundTransparency = 1
	name_l.Text                   = cd.CharacterName
	name_l.Font                   = Enum.Font.GothamBold
	name_l.TextSize               = 17
	name_l.TextScaled             = false
	name_l.TextColor3             = Color3.fromRGB(240, 240, 245)
	name_l.TextStrokeTransparency = 0.5
	name_l.TextXAlignment         = Enum.TextXAlignment.Left

	local anime_l                  = Instance.new("TextLabel", card)
	anime_l.Size                   = UDim2.new(1, 0, 0, 13)
	anime_l.Position               = UDim2.new(0, 0, 0, 46)
	anime_l.BackgroundTransparency = 1
	anime_l.Text                   = cd.Anime or ""
	anime_l.Font                   = Enum.Font.Gotham
	anime_l.TextSize               = 13
	anime_l.TextColor3             = ANIME_COLORS_DS[cd.Anime or ""] or Color3.fromRGB(160, 160, 190)
	anime_l.TextStrokeTransparency = 0.5
	anime_l.TextXAlignment         = Enum.TextXAlignment.Left

	local sep                  = Instance.new("Frame", card)
	sep.Size                   = UDim2.new(1, 0, 0, 1)
	sep.Position               = UDim2.new(0, 0, 0, 62)
	sep.BackgroundColor3       = rarity_color
	sep.BackgroundTransparency = 0.65
	sep.BorderSizePixel        = 0

	local inc_text = "+" .. formatNumber(actual_income) .. "/s"
	if stars > 1 then inc_text = inc_text .. " (x" .. string.format("%.1f", star_mult) .. ")" end

	local inc_l                  = Instance.new("TextLabel", card)
	inc_l.Size                   = UDim2.new(1, 0, 0, 16)
	inc_l.Position               = UDim2.new(0, 0, 0, 67)
	inc_l.BackgroundTransparency = 1
	inc_l.Text                   = inc_text
	inc_l.Font                   = Enum.Font.GothamBold
	inc_l.TextSize               = 12
	inc_l.TextColor3             = Color3.fromRGB(100, 255, 120)
	inc_l.TextStrokeTransparency = 0.4
	inc_l.TextXAlignment         = Enum.TextXAlignment.Left

	local rarity_highlights = {
		Secret    = {fill=Color3.fromRGB(255,255,0),   fillT=0.3, outline=Color3.fromRGB(255,0,0),    outlineT=0},
		Celestial = {fill=Color3.fromRGB(255,255,100), fillT=0.5, outline=Color3.fromRGB(255,200,0),  outlineT=0.2},
		Ascendent = {fill=Color3.fromRGB(255,255,255), fillT=0.6, outline=Color3.fromRGB(200,200,255),outlineT=0.3},
		Mythic    = {fill=Color3.fromRGB(255,0,100),   fillT=0.7, outline=Color3.fromRGB(255,50,150), outlineT=0.4},
	}
	local hl = rarity_highlights[cd.Rarity]
	if hl then
		local h               = Instance.new("Highlight")
		h.FillColor           = hl.fill
		h.FillTransparency    = hl.fillT
		h.OutlineColor        = hl.outline
		h.OutlineTransparency = hl.outlineT
		h.Parent              = char
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

-- restore a player from saved data

local function restore_player(player, data)
	if not data then return end
	local ls = player:WaitForChild("leaderstats", 10)
	if not ls then return end
	local coins = ls:FindFirstChild("Coins")
	if coins and data.Coins and data.Coins > 0 then coins.Value = data.Coins end
	local rebirths = ls:FindFirstChild("Rebirths")
	if rebirths and data.Rebirths then
		rebirths.Value = data.Rebirths
		player:SetAttribute("CashMultiplier",  get_cash_multiplier(data.Rebirths))
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
	local bp_perks = {
		"HasBP_x2Luck", "HasBP_x2Coins", "HasBP_x2Speed",
		"HasBP_ExtraSlots", "HasBP_RebirthSave", "HasBP_SaveAll", "HasPremiumSlapTool",
	}
	for _, perk in ipairs(bp_perks) do
		if data[perk] then player:SetAttribute(perk, true) end
	end
	if data.IndexLuck then player:SetAttribute("IndexLuck", data.IndexLuck) end
	if data.IndexCollected then
		for _, anime in ipairs(data.IndexCollected) do
			player:SetAttribute("IndexCollected_" .. anime, true)
		end
	end
	task.delay(2, function()
		local bp = get_base_plateau(player)
		if bp then
			local color_level = player:GetAttribute("SelectedBaseTheme") or (data.Rebirths or 0)
			bp.Color    = ANIME_BASE_COLORS[color_level] or Color3.fromRGB(108, 59, 245)
			bp.Material = Enum.Material.SmoothPlastic
		end
	end)
	task.wait(0.5)
	local bp = get_base_plateau(player)
	if not bp then
		warn("[DataStore] BasePlateau not found for " .. player.Name)
		return
	end
	local _, stor, ic = ensure_inventory(player)
	if data.SlotPositions then
		for k, rel in pairs(data.SlotPositions) do
			local slot = bp:FindFirstChild("Slot" .. tonumber(k))
			if slot and slot:IsA("BasePart") then
				slot.Position = bp.Position + Vector3.new(rel[1], rel[2], rel[3])
			end
		end
	end
	if data.SlotCharacters then
		for k, cd in pairs(data.SlotCharacters) do
			local slot = bp:FindFirstChild("Slot" .. tonumber(k))
			if slot then
				for _, child in pairs(slot:GetChildren()) do
					if child.Name == "PlacedCharacter" then child:Destroy() end
				end
				local restored = spawn_character_from_data(cd, slot, slot.Position + Vector3.new(0, 2, 0))
				slot:SetAttribute("Occupied", true)
				if restored then discover_character(player, cd.CharacterName) end
			end
		end
	end
	if data.StorageCharacters and #data.StorageCharacters > 0 then
		for _, cd in pairs(data.StorageCharacters) do
			local char = spawn_character_from_data(cd, stor, Vector3.new(0, -200, 0))
			if char then
				ic.Value = ic.Value + 1
				discover_character(player, cd.CharacterName)
			end
		end
	end
	if data.DiscoveredCharacters then
		for _, char_name in pairs(data.DiscoveredCharacters) do
			discover_character(player, char_name)
		end
	end
	if data.SeenCharacters then
		local seen = player:FindFirstChild("SeenCharacters")
		if not seen then
			seen        = Instance.new("Folder")
			seen.Name   = "SeenCharacters"
			seen.Parent = player
		end
		for _, char_name in pairs(data.SeenCharacters) do
			if not seen:FindFirstChild(char_name) then
				local tag     = Instance.new("BoolValue")
				tag.Name      = char_name
				tag.Value     = true
				tag.Parent    = seen
			end
		end
	end
	if data.ShowcaseCharacter then
		task.delay(3, function()
			local b2 = get_base_plateau(player)
			if not b2 then return end
			local pedestal = b2:FindFirstChild("ShowcasePedestal")
			if not pedestal then return end
			for _, child in pairs(pedestal:GetChildren()) do
				if child:IsA("BasePart") and child.Name == "ShowcaseCharacter" then child:Destroy() end
			end
			local cd   = migrate_char_data(data.ShowcaseCharacter)
			local char = spawn_character_from_data(cd, pedestal, pedestal.Position + Vector3.new(0, 3, 0))
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
	local collected = data.IndexCollected and #data.IndexCollected or 0
	print("[DataStore] Restored " .. player.Name
		.. " | coins: "      .. formatNumber(data.Coins or 0)
		.. " | rebirths: "   .. (data.Rebirths or 0)
		.. " | multiplier: " .. get_cash_multiplier(data.Rebirths or 0) .. "x"
		.. " | vip: "        .. tostring(data.IsVIP or false)
		.. " | indexLuck: "  .. (data.IndexLuck or 0)
		.. " (" .. collected .. " collected)"
		.. " | time: "       .. format_time_played(data.TimePlayed or 0))
end

-- player added

Players.PlayerAdded:Connect(function(player)
	session_start_times[player.UserId] = os.time()
	task.wait(0.5)
	local data = load_player_data(player)
	local has_data = data and (
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
	if has_data then
		restore_player(player, data)
	else
		player:SetAttribute("TimePlayedMinutes", 0)
		print("[DataStore] New player: " .. player.Name)
	end
	session_data[player.UserId] = true
end)

-- player removing

Players.PlayerRemoving:Connect(function(player)
	local mins = get_session_minutes(player)
	player:SetAttribute("TimePlayedMinutes",
		(player:GetAttribute("TimePlayedMinutes") or 0) + mins)
	session_start_times[player.UserId] = nil
	save_player_data(player)
	session_data[player.UserId] = nil
end)

-- autosave loop

task.spawn(function()
	while true do
		task.wait(AUTOSAVE_INTERVAL)
		for _, player in pairs(Players:GetPlayers()) do
			task.spawn(function() save_player_data(player) end)
		end
	end
end)

game:BindToClose(function()
	for _, player in pairs(Players:GetPlayers()) do
		local mins = get_session_minutes(player)
		player:SetAttribute("TimePlayedMinutes",
			(player:GetAttribute("TimePlayedMinutes") or 0) + mins)
		save_player_data(player)
	end
end)

-- grant special character (fired by ShopHandler when a player buys directly)

local grant_special_char  = Instance.new("BindableEvent")
grant_special_char.Name   = "GrantSpecialCharacter"
grant_special_char.Parent = game:GetService("ServerScriptService")

grant_special_char.Event:Connect(function(player, cd)
	if not player or not player.Parent then return end
	local max_storage   = GD.STORAGE_PER_REBIRTH[player:GetAttribute("RebirthCount") or 0] or 4
	local _, stor, _ = ensure_inventory(player)
	if not stor then return end
	if #stor:GetChildren() >= max_storage then
		local ne = ReplicatedStorage:FindFirstChild("NotifyEvent")
		if ne then ne:FireClient(player, "Storage is full! Free up space first.", "warning") end
		return
	end
	local char = spawn_character_from_data(cd, stor, Vector3.new(0, -500, 0))
	char.Parent = stor
	discover_character(player, cd.CharacterName)
	save_player_data(player)
end)

print("[DataStore] handler loaded")
