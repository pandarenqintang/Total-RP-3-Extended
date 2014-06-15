--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
-- Total RP 3
-- Register : Ignore list
--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*

local Events = TRP3_API.events;
local showTextInputPopup = TRP3_API.popup.showTextInputPopup;
local loc = TRP3_API.locale.getText;
local assert, tostring, time, wipe, strconcat, pairs, tinsert = assert, tostring, time, wipe, strconcat, pairs, tinsert;
local EMPTY = TRP3_API.globals.empty;
local UnitIsPlayer = UnitIsPlayer;
local get, getPlayerCurrentProfile, hasProfile = TRP3_API.profile.getData, TRP3_API.profile.getPlayerCurrentProfile, TRP3_API.register.hasProfile;
local getProfile, getUnitID = TRP3_API.register.getProfile, TRP3_API.utils.str.getUnitID;
local displayDropDown = TRP3_API.ui.listbox.displayDropDown;
local registerInfoTypes = TRP3_API.register.registerInfoTypes;
local getCompleteName, getPlayerCompleteName;
local profiles, characters, blackList, whiteList;

--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
-- Relation
--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*

local RELATIONS = {
	UNFRIENDLY = "UNFRIENDLY",
	NONE = "NONE",
	NEUTRAL = "NEUTRAL",
	BUSINESS = "BUSINESS",
	FRIEND = "FRIEND",
	LOVE = "LOVE",
	FAMILY = "FAMILY"
}
TRP3_API.register.relation = RELATIONS;

local RELATIONS_TEXTURES = {
	[RELATIONS.UNFRIENDLY] = "Ability_DualWield",
	[RELATIONS.NONE] = "Ability_rogue_disguise",
	[RELATIONS.NEUTRAL] = "Achievement_Reputation_05",
	[RELATIONS.BUSINESS] = "Achievement_Reputation_08",
	[RELATIONS.FRIEND] = "Achievement_Reputation_06",
	[RELATIONS.LOVE] = "INV_ValentinesCandy",
	[RELATIONS.FAMILY] = "Achievement_Reputation_07"
}

local function setRelation(profileID, relation)
	local profile = getPlayerCurrentProfile();
	if not profile.relation then
		profile.relation = {};
	end
	profile.relation[profileID] = relation;
end
TRP3_API.register.relation.setRelation = setRelation;

local function getRelation(profileID)
	local relationTab = get("relation") or EMPTY;
	return relationTab[profileID] or RELATIONS.NONE;
end
TRP3_API.register.relation.getRelation = getRelation;

local function getRelationText(profileID)
	local relation = getRelation(profileID);
	if relation == RELATIONS.NONE then
		return "";
	end
	return loc("REG_RELATION_" .. relation);
end
TRP3_API.register.relation.getRelationText = getRelationText;

local function getRelationTooltipText(profileID, profile)
	return loc("REG_RELATION_" .. getRelation(profileID) .. "_TT"):format(getPlayerCompleteName(true), getCompleteName(profile.characteristics or EMPTY, UNKNOWN, true));
end
TRP3_API.register.relation.getRelationTooltipText = getRelationTooltipText;

local function getRelationTexture(profileID)
	return RELATIONS_TEXTURES[getRelation(profileID)];
end
TRP3_API.register.relation.getRelationTexture = getRelationTexture;

--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
-- Ignore list
--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*

local function isIDIgnored(ID)
	return blackList[ID] ~= nil;
end
TRP3_API.register.isIDIgnored = isIDIgnored;

local function ignoreID(unitID)
	showTextInputPopup(loc("TF_IGNORE_CONFIRM"):format(unitID), function(text)
		if text:len() == 0 then
			text = loc("TF_IGNORE_NO_REASON");
		end
		blackList[unitID] = text;
		Events.fireEvent(Events.REGISTER_DATA_CHANGED, unitID);
	end);
end
TRP3_API.register.ignoreID = ignoreID;

local function getIgnoreReason(unitID)
	return blackList[unitID];
end
TRP3_API.register.getIgnoreReason = getIgnoreReason;

function TRP3_API.register.purgeIgnored(ID)
	local charactersToIgnore = {};
	local profileToIgnore;
	
	-- Determine what to ignore
	if characters[ID] then
		profileToIgnore = characters[ID].profileID;
		if profiles[profileToIgnore] then
			local links = profiles[profileToIgnore].link or EMPTY;
			for unitID, _ in pairs(links) do
				tinsert(charactersToIgnore, unitID);
			end
		end
	end
	-- Ignore and delete all characters !
	for _, unitID in pairs(charactersToIgnore) do
		blackList[unitID] = true;
		if characters[unitID] then
			wipe(characters[unitID]);
			characters[unitID] = nil;
		end
		Events.fireEvent(Events.REGISTER_DATA_CHANGED, unitID);
	end
	-- Delete related profile
	if profileToIgnore and profiles[profileToIgnore] then
		wipe(profiles[profileToIgnore]);
		profiles[profileToIgnore] = nil;
		Events.fireEvent(Events.REGISTER_PROFILE_DELETED, profileToIgnore);
	end
end

function TRP3_API.register.unignoreID(unitID)
	blackList[unitID] = nil;
	Events.fireEvent(Events.REGISTER_DATA_CHANGED, unitID);
end

function TRP3_API.register.getIgnoredList()
	return blackList;
end

--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
-- Init
--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*

local function onRelationSelected(value)
	local unitID = getUnitID("target");
	if hasProfile(unitID) then
		setRelation(hasProfile(unitID), value);
		Events.fireEvent(Events.REGISTER_DATA_CHANGED, unitID, hasProfile(unitID));
		Events.fireEvent(Events.REGISTER_EXCHANGE_RECEIVED_INFO, hasProfile(unitID), registerInfoTypes.CHARACTERISTICS);
	end
end

local function onTargetButtonClicked(unitID, _, _, button)
	local profileID = hasProfile(unitID);
	local values = {};
	tinsert(values, {loc("REG_RELATION"), nil});
	tinsert(values, {loc("REG_RELATION_NONE"), RELATIONS.NONE});
	tinsert(values, {loc("REG_RELATION_UNFRIENDLY"), RELATIONS.UNFRIENDLY});
	tinsert(values, {loc("REG_RELATION_NEUTRAL"), RELATIONS.NEUTRAL});
	tinsert(values, {loc("REG_RELATION_BUSINESS"), RELATIONS.BUSINESS});
	tinsert(values, {loc("REG_RELATION_FRIEND"), RELATIONS.FRIEND});
	tinsert(values, {loc("REG_RELATION_LOVE"), RELATIONS.LOVE});
	tinsert(values, {loc("REG_RELATION_FAMILY"), RELATIONS.FAMILY});
	displayDropDown(button, values, onRelationSelected, 0, true);
end

Events.listenToEvent(Events.WORKFLOW_ON_LOADED, function()
	getCompleteName, getPlayerCompleteName = TRP3_API.register.getCompleteName, TRP3_API.register.getPlayerCompleteName;

	if not TRP3_Register.blackList then
		TRP3_Register.blackList = {};
	end
	if not TRP3_Register.whiteList then
		TRP3_Register.whiteList = {};
	end
	profiles = TRP3_Register.profiles;
	characters = TRP3_Register.character;
	blackList = TRP3_Register.blackList;
	whiteList = TRP3_Register.whiteList;
	
	-- Ignore button on target frame
	local player_id = TRP3_API.globals.player_id;
	TRP3_API.target.registerButton({
		id = "z_ignore",
		configText = loc("TF_IGNORE"),
		condition = function(unitID, targetInfo)
			return UnitIsPlayer("target") and unitID ~= player_id and not isIDIgnored(unitID);
		end,
		onClick = function(unitID)
			ignoreID(unitID);
		end,
		tooltipSub = loc("TF_IGNORE_TT"),
		tooltip = loc("TF_IGNORE"),
		icon = "Achievement_BG_interruptX_flagcapture_attempts_1game"
	});
	
	TRP3_API.target.registerButton({
		id = "r_relation",
		configText = loc("REG_RELATION"),
		condition = function(unitID, targetInfo)
			return UnitIsPlayer("target") and unitID ~= player_id and hasProfile(unitID);
		end,
		onClick = onTargetButtonClicked,
		adapter = function(buttonStructure, unitID)
			local profileID = hasProfile(unitID);
			buttonStructure.tooltip = loc("REG_RELATION") .. ": " .. getRelationText(profileID);
			buttonStructure.tooltipSub = "|cff00ff00" .. getRelationTooltipText(profileID, getProfile(profileID)) .. "\n" .. loc("REG_RELATION_TARGET");
			buttonStructure.icon = getRelationTexture(profileID);
		end,
	});
end);
