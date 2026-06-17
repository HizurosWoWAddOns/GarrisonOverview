
local addon, ns = ...
local L = ns.L
local ldbObject
local icon = 1005027
local LDB = LibStub("LibDataBroker-1.1")
local LDBI = LibStub("LibDBIcon-1.0")
local LQT = LibStub("LibQTip-1.0")
local lvlColor = {--[[ [0]=ITEM_POOR_COLOR, ]]ITEM_GOOD_COLOR,ITEM_SUPERIOR_COLOR,ITEM_EPIC_COLOR} --ITEM_QUALITY_COLORS
local C = NORMAL_FONT_COLOR.WrapTextInColorCode
local tt

local color = {};
do
	local c = {
		"ltyellow", "fff569",
		"ltblue", "69ccf0",
		"ltgray", "b0b0b0",
	}
	for i=1, #c, 2 do
		local n, h = c[i],c[i+1]
		local rgb={} for j=1, 6, 2 do tinsert(rgb,tonumber(h:sub(j,j+1),16)/255) end
		local t = CopyTable(NORMAL_FONT_COLOR)
		t.r,t.g,t.b,t.colorStr=rgb[1],rgb[2],rgb[3],"ff"..h
		color[n]=t;
	end
	lvlColor[0] = color.ltgray
end

ns.broker = {}

local function pairsLineCells(name_realm,data,tar)
	local lst = {
		false,
		{show=true,str=C(color.ltyellow,GARRISON_LOCATION_TOOLTIP)},
		{show=ns.db[tar.."Shipyard"],str=C(color.ltyellow,L["Shipyard"])},
		{show=ns.db[tar.."Garden"],str=C(color.ltyellow,L["Garden"])},
		{show=ns.db[tar.."Mine"],str=C(color.ltyellow,L["Mine"])},
		{show=ns.db[tar.."Cache"],str=C(color.ltyellow,GARRISON_CACHE)},
		--{show=ns.db.ttResources,str=""},
	}
	if data then
		if data.buildings==0 then
			lst[2].str=C(color.ltgray,NONE_KEY)
			lst[3].str=""
			lst[4].str=""
			lst[5].str=""
			lst[6].str=""
			--lst[7].str=""
		else
			local gLvl = data.buildings[ns.buildingIndex.garrison]
			local sLvl = data.buildings[ns.buildingIndex.shipyard] and data.buildings[ns.buildingIndex.shipyard][ns.buildingInfo.rank] or 0
			local hLvl = data.buildings[ns.buildingIndex.garden] and data.buildings[ns.buildingIndex.garden][ns.buildingInfo.rank] or 0
			local mLvl = data.buildings[ns.buildingIndex.mine] and data.buildings[ns.buildingIndex.mine][ns.buildingInfo.rank] or 0
			lst[2].str=C(lvlColor[gLvl],gLvl)
			lst[3].str=C(lvlColor[sLvl],sLvl==0 and NONE_KEY or sLvl)
			lst[4].str=C(lvlColor[hLvl],hLvl==0 and NONE_KEY or hLvl)..(hLvl>0 and " "..ns.getLoot(name_realm,"garden") or "")
			lst[5].str=C(lvlColor[mLvl],mLvl==0 and NONE_KEY or mLvl)..(mLvl>0 and " "..ns.getLoot(name_realm,"mine") or "")
			lst[6].str=ns.cacheForecast(name_realm)
			--lst[7].str=data.resources
		end
	end
	local i=1
	local iter = function()
		i=i+1
		if lst[i] then
			return i, lst[i].show, lst[i].str
		end
	end
	return iter
end

local function createTooltip()
	if not tt then return end
	tt:Clear()
	tt:AddHeader(addon)
	for index, name_realm, toonName, toonRealm, data in ns.pairsByToons() do
		if not data then tt:AddSeparator(4,0,0,0,0) end
		local l = tt:AddLine(data and toonName or name_realm)
		if not toonRealm or (toonRealm and not ns.db.collapsed[toonRealm]) then
			if not data then tt:AddSeparator() end
			for i, show, str in pairsLineCells(name_realm,data,"tt") do
				if show then
					tt:SetCell(l,i,str)
				end
			end
			if name_realm==ns.playerName then
				tt:SetLineColor(l, 1,1,0,.35)
			end
		end
	end
end

---@param choose boolean|nil Update tooltip(true), broker(false) or both(nil)
function ns.broker.update(choose)
	if not choose then
		-- update broker button
		local txt,data = {},ns.getToon(ns.playerName)
		local gLvl = data.buildings[ns.buildingIndex.garrison]
		if gLvl>0 then
			for i, show, str in pairsLineCells(ns.playerName,data,"bb") do
				if show then
					tinsert(txt,str)
				end
			end
		else
			tinsert(txt,L["NoGarrison"])
		end
		if #txt==0 then
			tinsert(txt,addon)
		end
		ldbObject.text = table.concat(txt,", ")
	end
	if choose==true or choose==nil then
		-- update tooltip
	end
end

local function tooltipOnEnter(self)
	tt = LQT:Acquire(addon.."Tooltip",6,"LEFT","CENTER","CENTER","CENTER","CENTER","CENTER")
	createTooltip()
	tt:SmartAnchorTo(self)
	tt:Show()
end

local function tooltipOnLeave()
	tt:Hide()
	LQT:Release(tt)
	tt = nil
end

ns.event("VARIABLES_LOADED","broker",function()
	local ldbOblectTable = {
		-- button data
		type          = "data source",
		label         = addon,
		text          = addon,
		icon          = icon, -- default or custom icon
		staticIcon    = icon, -- default icon only
		--iconCoords    = iconCoords or {0, 1, 0, 1},

		-- button event functions
		OnEnter       = tooltipOnEnter,
		OnLeave       = tooltipOnLeave,
		--OnClick       = onclick,
		--OnTooltipShow = createTooltip,

		-- let user know who registered the broker
		-- displayable by broker dispay addons...
		-- DataBrokerGroups using it in option panel.
		parent        = addon
	}

	ldbObject = LDB:NewDataObject(addon,ldbOblectTable)
	--ns.LDBI:Register(addon,ldbObject,ns.db.mininap)
end)
