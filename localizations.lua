
local L, addon, ns = {}, ...;

ns.L = setmetatable(L,{__index=function(t,k)
	local v = tostring(k);
	rawset(t,k,v);
	return v;
end});

L["AddOnLoaded"] = "AddOn loaded..."
L["NoGarrison"] = "No garrison"
L["GarrLevelShort"] = "G"
L["SyLevelShort"] = "S"
L["CacheShort"] = "C"
L["HerbCountShort"] = "H"
L["MineCountShort"] = "M"

if LOCALE_deDE then
	L["AddOnLoaded"] = "AddOn geladen..."
	L["NoGarrison"] = "Keine Garnison"
elseif LOCALE_esES then
elseif LOCALE_esMX then
elseif LOCALE_frFR then
elseif LOCALE_itIT then
elseif LOCALE_koKR then
elseif LOCALE_ptBR or LOCALE_ptPT then
elseif LOCALE_ruRU then
elseif LOCALE_zhCN then
elseif LOCALE_zhTW then
end
