
local addon, ns = ...
local L = ns.L
ns.realmName = GetRealmName()
local _,classStr = UnitClass("player")
ns.playerName = UnitName("player").."-"..ns.realmName.."-"..classStr
ns.playerNameOld = UnitName("player").."-"..ns.realmName
ns.isAlliance = UnitFactionGroup("player")=="Alliance"
ns.isInGarrison = false
ns.gardenBuildingID = {[29]=1,[136]=2,[137]=3}
ns.minesBuildingID = {[61]=1,[62]=2,[63]=3}
ns.mineLootSlots = {[61]=8,[62]=13,[63]=18}
ns.gardenLootSlots = {[29]=6,[136]=10,[137]=15}
ns.buildingIndex = {garrison=1,mine=2,garden=3,fishing=4,menagerie=5,shipyard=6,big1=7,big2=8,middle1=9,middle2=10,small1=11,small2=12,small3=13}
ns.buildingInfo = {buildingID=1,rank=2,build=3,job=4,workorders=5}
local C = NORMAL_FONT_COLOR.WrapTextInColorCode
local toons,labels = {},{"buildings","cache","cache1k","gardenLoot","gardenLootReset","mineLoot","mineLootReset","resources"}
local garrMaps = {
	-- [<garrMapID>]=1, [<minesMapID>]=2
	[582]=1, [579]=2, [580]=2, [581]=2, -- alliance
	[590]=1, [585]=2, [586]=2, [587]=2, -- horde
}
local isLootObject = {
	[233117]="garden", [235376]="garden", [228572]="garden", [235387]="garden", [235388]="garden", [235389]="garden", [235391]="garden", [235390]="garden",
	[243313]="mine", [228564]="mine", [232543]="mine", [237360]="mine", [232542]="mine", [228453]="mine", [237359]="mine", [243312]="mine",
	[228493]="mine", [232544]="mine", [237357]="mine", [228510]="mine", [237358]="mine", [243315]="mine", [243314]="mine",

	[232545]="mine",
	--[235885]="mine",
}
local buildingOrder={ -- list of plotIDs
	 1, --  1 main building
	59, --  2 mine
	63, --  3 garden
	67, --  4 fishing shack
	81, --  5 menagerie
	98, --  6 shipyard
	23, --  7 big
	24, --  8 big
	22, --  9 middle
	25, -- 10 middle
	18, -- 11 small
	19, -- 12 small
	20  -- 13 small
}
local jobslots = {[25]=1,[27]=1,[28]=1,[62]=1,[63]=1,[117]=1,[118]=1,[119]=1,[120]=1,[121]=1,[122]=1,[123]=1,[124]=1,[125]=1,[126]=1,[127]=1,[128]=1,[129]=1,[130]=1,[131]=1,[132]=1,[133]=1,[135]=1,[136]=1,[137]=1,[138]=1}
local lootReadyLock = false
local dbDefaults = {
	ttShipyard=false,
	bbShipyard=false,
	ttCache=true,
	bbCache=true,
	ttGarden=true,
	bbGarden=true,
	ttMine=true,
	bbMine=true,
	ttResources=true,
	bbResources=true,
	--ttHideNone=true,
}

dbDefaults.collapsed = setmetatable({},{
	__newindex = function(t,k,v)
		ns.db["collapsed"..k]=v
	end,
	__index = function(t,k)
		return ns.db["collapsed"..k]
	end
})

dbDefaults.minimap = setmetatable({},{
	__newindex = function(t,k,v)
		ns.db["minimap-"..k]=v
	end,
	__index = function(t,k)
		return ns.db["minimap-"..k]
	end
})

local optsMT = {
	--__newindex = function()
	--end,
	__index = function(t,k)
		if dbDefaults[k] then
			return dbDefaults[k]
		end
		return
	end
}

local tConcatAll,tUnpackAll
do
	local delimiter,type = {":",";",".",",","^","°"},type
	function tConcatAll(data,lvl)
		if not lvl then lvl = 1 end
		local t = {}
		for i=1, #data do
			if type(data[i])=="table" then
				tinsert(t,tConcatAll(data[i],lvl+1))
			else
				tinsert(t,data[i])
			end
		end
		return table.concat(t,delimiter[lvl])
	end
	function tUnpackAll(str,lvl)
		if not lvl then lvl = 1 end
		local nextLvl = lvl+1
		local t = {strsplit(delimiter[lvl],str)}
		for i=1, #t do
			if t[i]:match("[,.;%^°]") then
				t[i] = tUnpackAll(t[i],nextLvl)
			else
				t[i] = tonumber(t[i]) or 0
			end
		end
		return t
	end
end

local function saveCurrentToon()
	local tmp = {}
	for _,label in ipairs(labels) do
		tinsert(tmp,toons[ns.playerName][label])
	end
	GarrisonOverviewDB.toons[ns.playerName] = tConcatAll(tmp)
	ns.broker.update()
end

function ns.pairsByToons()
	local t1,t2,tn,tr = {},{},{},{}
	local current
	-- step 1
	for toonNameRealm in pairs(toons) do
		local name,realm = strsplit("-",toonNameRealm,2)
		local realm_name = realm.."-"..name
		tn[realm_name] = {toonNameRealm,name,realm}
		if toonNameRealm==ns.playerName then
			current = realm_name
		end
		if not t1[realm] then
			t1[realm] = {realm} -- realm name as header
			tinsert(tr,realm)
		end
		tinsert(t1[realm], realm_name)
	end
	-- sort current realm
	table.sort(t1[ns.realmName])
	-- copy to second table
	for _, rn in ipairs(t1[ns.realmName])do
		if rn==current then
			tinsert(t2,2,rn) -- current player first
		else
			tinsert(t2,rn)
		end
	end
	-- sort realm list
	table.sort(tr)
	-- copy all other realm toons to second table
	for _, realm in ipairs(tr) do
		if realm~=ns.realmName then
			table.sort(t1[realm])
			for _, rn in ipairs(t1[realm])do
				tinsert(t2,rn)
			end
		end
	end
	local i=0
	local function iter()
		i=i+1
		local name = t2[i]
		if not name then
			return
		end
		if not name:match("%-") then
			return i, name -- realm name as header
		end
		local toonNameRealm, toonName, toonRealm = unpack(tn[name])
		return i, toonNameRealm, toonName, toonRealm, toons[toonNameRealm], toonNameRealm==ns.playerName
		-- index, toonNameRealm, toonName, toonRealm, toonData, isCurrent
	end
	return iter
end

function ns.getToon(toon)
	return toons[toon]
end

function ns.cacheForecast(toon,raw)
	local cache,cap = -1,toons[toon].cache1k==1 and 1000 or 500
	if toons[toon].cache>0 then
		cache = floor((time()-toons[toon].cache)/600)
		if cache>=cap then
			cache = cap
		end
	end
	if raw then
		return (cache>=0 and cache or "?"), cap
	end
	if cache<0 then
		return ORANGE_FONT_COLOR:WrapTextInColorCode("?/"..cap)
	end
	local forecastStr,forecastCap = cache.."/"..cap,cache/cap
	local color = (forecastCap==1 and RED_FONT_COLOR) or (forecastCap>=.75 and ORANGE_FONT_COLOR) or (forecastCap>=.5 and YELLOW_FONT_COLOR) or (cache<=5 and GRAY_FONT_COLOR)
	if color then
		forecastStr = color:WrapTextInColorCode(forecastStr)
	end
	return forecastStr
end

function ns.getLoot(toon,name)
	local data = toons[toon]
	local buildingID = data.buildings[ns.buildingIndex[name]] and data.buildings[ns.buildingIndex[name]][ns.buildingInfo.buildingID] or 0
	local lootSlots = ns[name.."LootSlots"][buildingID] or "?" -- ns.mineLootSlots / ns.gardenLootSlots
	local looted = data[name.."Loot"]
	local reset = data[name.."LootReset"]
	if reset < time() then
		return C(GREEN_FONT_COLOR,lootSlots.."/"..lootSlots)
	end
	local color = looted==lootSlots and GRAY_FONT_COLOR or YELLOW_FONT_COLOR
	return C(color,(lootSlots-looted).."/"..lootSlots)
end

ns.event("SHOW_LOOT_TOAST","data",function(...)
	local typeIdentifier, _, quantity, _, _, isPersonal, lootSource = ...
	if not (isPersonal==true and typeIdentifier=="currency" and lootSource==10) then
		return
	end
	toons[ns.playerName].cache=time() -- set time on looting cache for next forecast
	saveCurrentToon()
end)

local function getBuilding(plotID)
	local buildingID, name, texPrefix, icon, rank, isBuilding, timeStart, buildTime, canActivate, canUpgrade, isPrebuilt = C_Garrison.GetOwnedBuildingInfoAbbrev(plotID)
	local buildFinishedTime = isBuilding and (timeStart + buildTime) or 0
	local job=0 -- 0 no job, 1 job free, >1 follower added
	if jobslots[buildingID] then
		local _,_,_,_,fID = C_Garrison.GetFollowerInfoForBuilding(plotID)
		job = tonumber(fID) or 1
	end
	return { buildingID, rank, buildFinishedTime, job }
end

local function updateGarrison()
	local gLvl = C_Garrison.GetGarrisonInfo(Enum.GarrisonType.Type_6_0_Garrison) or 0

	toons[ns.playerName].buildings = {gLvl}
	if gLvl>0 then
		-- update buildings
		for i=2, #buildingOrder do
			tinsert(toons[ns.playerName].buildings,getBuilding(buildingOrder[i]))
		end

		-- check if cache is upgraded by Trade Agreement: Arakkoa Outcasts (itemId 128294, questId 37485)
		if toons[ns.playerName].cache1k==0 and C_QuestLog.IsQuestFlaggedCompleted(37485) then
			toons[ns.playerName].cache1k = 1
		end
	end

	saveCurrentToon()
end

ns.event("GARRISON_UPDATE","data",updateGarrison)
ns.event("GARRISON_BUILDING_UPDATE","data",updateGarrison)
	--"GARRISON_BUILDING_PLACED",
	--"GARRISON_BUILDING_REMOVED",
	--"GARRISON_BUILDING_LIST_UPDATE",
	--"GARRISON_BUILDING_ACTIVATED",
	--"GARRISON_UPGRADEABLE_RESULT",
	--"GARRISON_LANDINGPAGE_SHIPMENTS",

local function chkIsInGarrison()
	ns.isInGarrison = garrMaps[C_Map.GetBestMapForUnit("player")] or 0
	-- 0 = outside
	-- 1 = in garrison
	-- 2 = in garrison mine
end

ns.event("ZONE_CHANGED","chkIsInGarrison",chkIsInGarrison)
ns.event("ZONE_CHANGED_INDOORS","chkIsInGarrison",chkIsInGarrison)
ns.event("PLAYER_ENTERING_WORLD","chkIsInGarrison",chkIsInGarrison)

local function lootReadyUnlock()
	lootReadyLock=false
end

ns.event("LOOT_READY","data",function()
	chkIsInGarrison()
	if ns.isInGarrison==0 or lootReadyLock or GetLootSlotType(1)~=Enum.LootSlotType.Item then
		return
	end
	lootReadyLock = true
	local link,objType,gameObjectID = {strsplit("-",(GetLootSourceInfo(1)))},nil,nil
	if link and #link>0 and link[6] then
		gameObjectID = tonumber(link[6])
	end
	if gameObjectID then
		objType = isLootObject[gameObjectID]
	end
	if not objType then
		return
	end
	local lootNextReset = GetQuestResetTime()+time()
	local toon = toons[ns.playerName]
	if toon[objType.."LootReset"]==nil or (toon[objType.."LootReset"] and toon[objType.."LootReset"]<lootNextReset) then
		toon[objType.."Loot"] = 0
		toon[objType.."LootReset"] = lootNextReset
	end
	toon[objType.."Loot"] = toon[objType.."Loot"] + 1
	saveCurrentToon()
	C_Timer.After(1,lootReadyUnlock)
end)

ns.event("VARIABLES_LOADED","data",function()
	if not GarrisonOverviewDB then
		GarrisonOverviewDB = {}
	end
	if not GarrisonOverviewDB.toons then
		GarrisonOverviewDB.toons = {}
	end
	if GarrisonOverviewDB.toons[ns.playerNameOld] then
		GarrisonOverviewDB.toons[ns.playerName] = GarrisonOverviewDB.toons[ns.playerNameOld]
		GarrisonOverviewDB.toons[ns.playerNameOld] = nil
	elseif not GarrisonOverviewDB.toons[ns.playerName] then
		GarrisonOverviewDB.toons[ns.playerName] = ""
	end
	if not GarrisonOverviewDB.opts then
		GarrisonOverviewDB.opts = {}
	end
	if GarrisonOverviewDB.opts.minimap then
		GarrisonOverviewDB.opts.minimap = nil
	end

	ns.db = setmetatable(GarrisonOverviewDB.opts,optsMT)

	-- load toons
	for toon, toonData in pairs(GarrisonOverviewDB.toons) do
		toons[toon] = {}
		local tmp = tUnpackAll(toonData)
		for index, label in ipairs(labels) do
			toons[toon][label] = tmp[index] or 0
		end
	end
end)

