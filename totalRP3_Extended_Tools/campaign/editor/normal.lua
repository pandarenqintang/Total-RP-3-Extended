----------------------------------------------------------------------------------
-- Total RP 3: Extended features
--	---------------------------------------------------------------------------
--	Copyright 2015 Sylvain Cossement (telkostrasz@totalrp3.info)
--
--	Licensed under the Apache License, Version 2.0 (the "License");
--	you may not use this file except in compliance with the License.
--	You may obtain a copy of the License at
--
--		http://www.apache.org/licenses/LICENSE-2.0
--
--	Unless required by applicable law or agreed to in writing, software
--	distributed under the License is distributed on an "AS IS" BASIS,
--	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
--	See the License for the specific language governing permissions and
--	limitations under the License.
----------------------------------------------------------------------------------

local Globals, Events, Utils, EMPTY = TRP3_API.globals, TRP3_API.events, TRP3_API.utils, TRP3_API.globals.empty;
local tostring, tonumber, tinsert, strtrim, pairs, assert, wipe = tostring, tonumber, tinsert, strtrim, pairs, assert, wipe;
local tsize = Utils.table.size;
local getFullID, getClass = TRP3_API.extended.getFullID, TRP3_API.extended.getClass;
local stEtN = Utils.str.emptyToNil;
local loc = TRP3_API.locale.getText;
local setTooltipForSameFrame = TRP3_API.ui.tooltip.setTooltipForSameFrame;
local setTooltipAll = TRP3_API.ui.tooltip.setTooltipAll;
local color = Utils.str.color;
local toolFrame, main, pages, params, manager, notes, npc, quests;

local TABS = {
	MAIN = 1,
	WORKFLOWS = 2,
	QUESTS = 3,
	INNER = 4,
	EXPERT = 5
}

local tabGroup, currentTab;

--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
-- NPC
--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*

local function onIconSelected(icon)
	main.vignette.Icon:SetTexture("Interface\\ICONS\\" .. (icon or "TEMP"));
	main.vignette.selectedIcon = icon;
end

local function onNPCIconSelected(icon)
	TRP3_API.ui.frame.setupIconButton(npc.editor.icon, icon);
	npc.editor.icon.selectedIcon = icon;
end

local function decorateNPCLine(line, npcID)
	local data = toolFrame.specificDraft;
	local npcData = data.ND[npcID];

	TRP3_API.ui.frame.setupIconButton(line.Icon, npcData.IC or Globals.icons.profile_default);
	line.Name:SetText(npcData.NA or UNKNOWN);
	line.Description:SetText(npcData.DE or "");
	line.ID:SetText(loc("CA_NPC_ID") .. ": " .. npcID);
	line.click.npcID = npcID;
end

local function refreshNPCList()
	local data = toolFrame.specificDraft;
	TRP3_API.ui.list.initList(npc.list, data.ND, npc.list.slider);
	npc.list.empty:Hide();
	if tsize(data.ND) == 0 then
		npc.list.empty:Show();
	end
end

local function newNPC()
	npc.editor.oldID = nil;
	npc.editor.id:SetText("");
	npc.editor.name:SetText("");
	npc.editor.description.scroll.text:SetText("");
	onNPCIconSelected(Globals.icons.profile_default);
	TRP3_API.ui.frame.configureHoverFrame(npc.editor, npc.list.add, "TOP", 0, 5, false);
end

local function openNPC(npcID, frame)
	if not npcID then
		newNPC();
	else
		local npcData = toolFrame.specificDraft.ND[npcID];
		if npcData then
			npc.editor.oldID = npcID;
			npc.editor.id:SetText(npcID);
			npc.editor.name:SetText(npcData.NA or UNKNOWN);
			npc.editor.description.scroll.text:SetText(npcData.DE or "");
			onNPCIconSelected(npcData.IC or Globals.icons.profile_default);
			TRP3_API.ui.frame.configureHoverFrame(npc.editor, frame, "RIGHT", 0, 5, false);
		else
			newNPC();
		end
	end
end

local function onNPCSaved()
	local oldID = npc.editor.oldID;
	local ID = tostring(tonumber(strtrim(npc.editor.id:GetText())) or 0);
	local data = {
		NA = stEtN(strtrim(npc.editor.name:GetText())),
		DE = stEtN(strtrim(npc.editor.description.scroll.text:GetText())),
		IC = npc.editor.icon.selectedIcon or Globals.icons.profile_default
	}
	if ID then
		local structure = toolFrame.specificDraft.ND;
		if oldID and structure[oldID] then
			wipe(structure[oldID]);
			structure[oldID] = nil;
		end
		structure[ID] = data;
	end

	refreshNPCList();
	npc.editor:Hide();
end

local function removeNPC(id)
	TRP3_API.popup.showConfirmPopup(loc("CA_NPC_REMOVE"), function()
		if toolFrame.specificDraft.ND[id] then
			wipe(toolFrame.specificDraft.ND[id]);
			toolFrame.specificDraft.ND[id] = nil;
		end
		refreshNPCList();
		npc.editor:Hide();
	end);
end

--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
-- QUESTS
--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*

local function decorateQuestLine(line, questID)
	local data = toolFrame.specificDraft;
	local questData = data.QE[questID];

	TRP3_API.ui.frame.setupIconButton(line.Icon, questData.BA.IC or Globals.icons.default);
	line.Name:SetText(questData.BA.NA or UNKNOWN);
	line.Description:SetText(questData.BA.DE or "");
	line.ID:SetText(questID);
	line.click.questID = questID;
end

local function refreshQuestsList()
	local data = toolFrame.specificDraft;
	TRP3_API.ui.list.initList(quests.list, data.QE or EMPTY, quests.list.slider);
	quests.list.empty:Hide();
	if tsize(data.QE) == 0 then
		quests.list.empty:Show();
	end
end

local function removeQuest(questID)
	TRP3_API.popup.showConfirmPopup(loc("CA_QUEST_REMOVE"), function()
		if toolFrame.specificDraft.QE[questID] then
			wipe(toolFrame.specificDraft.QE[questID]);
			toolFrame.specificDraft.QE[questID] = nil;
		end
		refreshQuestsList();
	end);
end

local function openQuest(questID)
	TRP3_API.extended.tools.goToPage(getFullID(toolFrame.fullClassID, questID));
end

local function createQuest()
	TRP3_API.popup.showTextInputPopup(loc("CA_QUEST_CREATE"), function(value)
		if not toolFrame.specificDraft.QE[value] then
			toolFrame.specificDraft.QE[value] = TRP3_API.extended.tools.getQuestData();
			refreshQuestsList();
		else
			Utils.message.displayMessage(loc("CA_QUEST_EXIST"):format(value), 4);
		end
	end);
end

--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
-- Script & inner tabs
--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*

local function loadDataScript()
	-- Load workflows
	if not toolFrame.specificDraft.SC then
		toolFrame.specificDraft.SC = {};
	end
	TRP3_ScriptEditorNormal.loadList(TRP3_DB.types.CAMPAIGN);
end

local function storeDataScript()
	-- TODO: compute all workflow order
	for workflowID, workflow in pairs(toolFrame.specificDraft.SC) do
		TRP3_ScriptEditorNormal.linkElements(workflow);
	end
end

local function loadDataInner()
	-- Load inners
	if not toolFrame.specificDraft.IN then
		toolFrame.specificDraft.IN = {};
	end
	TRP3_InnerObjectEditor.refresh();
end

--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
-- Load ans save
--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*

local function load()
	assert(toolFrame.rootClassID, "rootClassID is nil");
	assert(toolFrame.fullClassID, "fullClassID is nil");
	assert(toolFrame.rootDraft, "rootDraft is nil");
	assert(toolFrame.specificDraft, "specificDraft is nil");

	local data = toolFrame.specificDraft;
	if not data.BA then
		data.BA = {};
	end
	if not data.ND then
		data.ND = {};
	end
	if not data.QE then
		data.QE = {};
	end

	main.name:SetText(data.BA.NA or "");
	main.description.scroll.text:SetText(data.BA.DE or "");
	main.range:SetText(data.BA.RA or "");
	onIconSelected(data.BA.IC);

	main.vignette.name:SetText(data.BA.NA or "");
	main.vignette.range:SetText(data.BA.RA or "");

	notes.frame.scroll.text:SetText(data.NT or "");

	loadDataScript();
	loadDataInner();

	tabGroup:SelectTab(TRP3_Tools_Parameters.editortabs[toolFrame.fullClassID] or TABS.MAIN);
end

local function saveToDraft()
	assert(toolFrame.specificDraft, "specificDraft is nil");

	local data = toolFrame.specificDraft;
	data.BA.NA = stEtN(strtrim(main.name:GetText()));
	data.BA.DE = stEtN(strtrim(main.description.scroll.text:GetText()));
	data.BA.RA = stEtN(strtrim(main.range:GetText()));
	data.BA.IC = main.vignette.selectedIcon;
	data.NT = stEtN(strtrim(notes.frame.scroll.text:GetText()));
	storeDataScript();
end

--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
-- UI
--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*

local function onTabChanged(tabWidget, tab)
	assert(toolFrame.fullClassID, "fullClassID is nil");

	-- Hide all
	currentTab = tab or TABS.MAIN;
	main:Hide();
	npc:Hide();
	notes:Hide();
	quests:Hide();
	TRP3_ScriptEditorNormal:Hide();
	TRP3_InnerObjectEditor:Hide();

	-- Show tab
	if currentTab == TABS.MAIN then
		main:Show();
		notes:Show();
		npc:Show();
		refreshNPCList();
	elseif currentTab == TABS.WORKFLOWS then
		TRP3_ScriptEditorNormal:SetParent(toolFrame.campaign.normal);
		TRP3_ScriptEditorNormal:SetAllPoints();
		TRP3_ScriptEditorNormal:Show();
	elseif currentTab == TABS.QUESTS then
		quests:Show();
		refreshQuestsList();
	elseif currentTab == TABS.INNER then
		TRP3_InnerObjectEditor:SetParent(toolFrame.campaign.normal);
		TRP3_InnerObjectEditor:SetAllPoints();
		TRP3_InnerObjectEditor:Show();
	end

	TRP3_Tools_Parameters.editortabs[toolFrame.fullClassID] = currentTab;
end

local function createTabBar()
	local frame = CreateFrame("Frame", "TRP3_ToolFrameCampaignNormalTabPanel", toolFrame.campaign.normal);
	frame:SetSize(400, 30);
	frame:SetPoint("BOTTOMLEFT", frame:GetParent(), "TOPLEFT", 15, 0);

	tabGroup = TRP3_API.ui.frame.createTabPanel(frame,
		{
			{ loc("EDITOR_MAIN"), TABS.MAIN, 150 },
			{ loc("QE_QUESTS"), TABS.QUESTS, 150 },
			{ loc("IN_INNER"), TABS.INNER, 150 },
			{ loc("WO_WORKFLOW"), TABS.WORKFLOWS, 150 },
			{ loc("WO_EXPERT"), TABS.EXPERT, 150 },
		},
		onTabChanged
	);
end

--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
-- INIT
--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*

function TRP3_API.extended.tools.initCampaignEditorNormal(ToolFrame)
	toolFrame = ToolFrame;
	toolFrame.campaign.normal.load = load;
	toolFrame.campaign.normal.saveToDraft = saveToDraft;

	createTabBar();

	--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
	-- MAIN
	--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*

	-- Main
	main = toolFrame.campaign.normal.main;
	main.title:SetText(loc("TYPE_CAMPAIGN"));

	-- Name
	main.name.title:SetText(loc("CA_NAME"));
	setTooltipForSameFrame(main.name.help, "RIGHT", 0, 5, loc("CA_NAME"), loc("CA_NAME_TT"));

	-- Description
	main.description.title:SetText(loc("CA_DESCRIPTION"));
	setTooltipAll(main.description.dummy, "RIGHT", 0, 5, loc("CA_DESCRIPTION"), loc("CA_DESCRIPTION_TT"));

	-- Range
	main.range.title:SetText(loc("CA_RANGE"));
	setTooltipForSameFrame(main.range.help, "RIGHT", 0, 5, loc("CA_RANGE"), loc("CA_RANGE_TT"));

	-- Vignette
	main.vignette.current:Hide();
	main.vignette.bgImage:SetTexture("Interface\\Garrison\\GarrisonUIBackground");
	main.vignette.Icon:SetVertexColor(0.7, 0.7, 0.7);
	main.vignette:SetScript("OnClick", function(self)
		TRP3_API.popup.showPopup(TRP3_API.popup.ICONS, {parent = self, point = "RIGHT", parentPoint = "LEFT"}, {onIconSelected});
	end);
	setTooltipAll(main.vignette, "RIGHT", 0, 5, loc("CA_ICON"), color("y") .. loc("CM_CLICK") .. ":|cffff9900 " .. loc("CA_ICON_TT"));

	--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
	-- NOTES
	--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*

	-- Notes
	notes = toolFrame.campaign.normal.notes;
	notes.title:SetText(loc("EDITOR_NOTES"));

	--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
	-- NPC
	--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*

	npc = toolFrame.campaign.normal.npc;
	npc.title:SetText(loc("CA_NPC"));
	npc.help:SetText(loc("CA_NPC_TT"));

	-- List
	npc.list.widgetTab = {};
	for i=1, 4 do
		local line = npc.list["line" .. i];
		tinsert(npc.list.widgetTab, line);
		line.click:SetScript("OnClick", function(self, button)
			if button == "RightButton" then
				removeNPC(self.npcID);
			else
				openNPC(self.npcID, self);
			end
		end);
		line.click:SetScript("OnEnter", function(self)
			TRP3_RefreshTooltipForFrame(self);
			self:GetParent().Highlight:Show();
		end);
		line.click:SetScript("OnLeave", function(self)
			TRP3_MainTooltip:Hide();
			self:GetParent().Highlight:Hide();
		end);
		line.click:RegisterForClicks("LeftButtonUp", "RightButtonUp");
		setTooltipForSameFrame(line.click, "RIGHT", 0, 5, loc("CA_NPC_UNIT"),
			("|cffffff00%s: |cff00ff00%s\n"):format(loc("CM_CLICK"), loc("CM_EDIT")) .. ("|cffffff00%s: |cff00ff00%s"):format(loc("CM_R_CLICK"), REMOVE));
	end
	npc.list.decorate = decorateNPCLine;
	TRP3_API.ui.list.handleMouseWheel(npc.list, npc.list.slider);
	npc.list.slider:SetValue(0);
	npc.list.add:SetText(loc("CA_NPC_ADD"));
	npc.list.add:SetScript("OnClick", function() openNPC() end);
	npc.list.empty:SetText(loc("CA_NO_NPC"));

	-- Editor
	npc.editor.title:SetText(loc("CA_NPC_EDITOR"));
	npc.editor.id.title:SetText(loc("CA_NPC_ID"));
	setTooltipForSameFrame(npc.editor.id.help, "RIGHT", 0, 5, loc("CA_NPC_ID"), loc("CA_NPC_ID_TT"));
	npc.editor.name.title:SetText(loc("CA_NPC_EDITOR_NAME"));
	npc.editor.description.title:SetText(loc("CA_NPC_EDITOR_DESC"));
	npc.editor.icon:SetScript("OnClick", function(self)
		TRP3_API.popup.showPopup(TRP3_API.popup.ICONS, {parent = npc.editor, point = "RIGHT", parentPoint = "LEFT"}, {onNPCIconSelected});
	end);
	npc.editor.save:SetScript("OnClick", function(self)
		onNPCSaved();
	end);

	--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
	-- QUEST
	--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*

	quests = toolFrame.campaign.normal.quests;
	quests.title:SetText(loc("QE_QUESTS"));
	quests.help:SetText(loc("QE_QUESTS_HELP"));

	-- List
	quests.list.widgetTab = {};
	for i=1, 4 do
		local line = quests.list["line" .. i];
		tinsert(quests.list.widgetTab, line);
		line.click:SetScript("OnClick", function(self, button)
			if button == "RightButton" then
				removeQuest(self.questID);
			else
				openQuest(self.questID);
			end
		end);
		line.click:SetScript("OnEnter", function(self)
			TRP3_RefreshTooltipForFrame(self);
			self:GetParent().Highlight:Show();
		end);
		line.click:SetScript("OnLeave", function(self)
			TRP3_MainTooltip:Hide();
			self:GetParent().Highlight:Hide();
		end);
		line.click:RegisterForClicks("LeftButtonUp", "RightButtonUp");
		setTooltipForSameFrame(line.click, "RIGHT", 0, 5, loc("TYPE_QUEST"),
			("|cffffff00%s: |cff00ff00%s\n"):format(loc("CM_CLICK"), loc("CM_EDIT")) .. ("|cffffff00%s: |cff00ff00%s"):format(loc("CM_R_CLICK"), REMOVE));
	end
	quests.list.decorate = decorateQuestLine;
	TRP3_API.ui.list.handleMouseWheel(quests.list, quests.list.slider);
	quests.list.slider:SetValue(0);
	quests.list.add:SetText(loc("CA_QUEST_ADD"));
	quests.list.add:SetScript("OnClick", function() createQuest() end);
	quests.list.empty:SetText(loc("CA_QUEST_NO"));

end