local GM = AceLibrary("AceAddon-2.0"):new("AceConsole-2.0", "AceEvent-2.0");


local myNotAddedMembers = {};
local myParty = {};
local myDPSCount = 0;
local myTankCount = 0;
local myHealerCount = 0;
local myInstance = nil;
local myIsSearching = nil;
local myIsInstanceFinished = true;

local function PrintLFMMessage()
	if(myIsSearching == nil or myInstance == nil) then
		return;
	end;
	
	local message = "LFM " .. myInstance .."! Need ";
	if(myTankCount == 0) then
		message = message .. "1 Tank";
	end;
	
	if(myHealerCount == 0) then
		if(myTankCount == 0) then
			message = message .. ", ";
		end;
		
		message = message .. "1 Healer";
	end;
	
	if(myDPSCount < 3) then
		if(myTankCount == 0 or myHealerCount == 0) then
			message = message .. ", ";
		end;
		
		message = message .. 3 - myDPSCount .. " Dps";
	end;
	
	message = message .. ". Whisp for invite.";
	
	--CU:PartyMessage(message);
	CU:WorldMessage(message);
	
	GM:ScheduleEvent(PrintLFMMessage, 45);
end

function GM:AskForRole(aName)
	local message = "Are you ";
	if(myTankCount == 0) then
		message = message .. "Tank";
	end;
	
	if(myHealerCount == 0) then
		if(myTankCount == 0) then
			message = message .. ", ";
		end;
		
		message = message .. "Healer";
	end;
	
	if(myDPSCount < 3) then
		if(myTankCount == 0 or myHealerCount == 0) then
			message = message .. " or ";
		end;
		
		message = message .. "Dps";
	end;
	
	message = message .. "?";
	
	SendChatMessage(message, "WHISPER", nil, aName);
end;

function GM:PrintGroupRoles()
	local tank = "";
	local healer = "";
	local dpses = "";
	for name,role in pairs(myParty) do
		if(role == "dps") then
			dpses = dpses .. " " .. name .. ",";
		elseif(role == "healer") then
			healer = name;
		elseif(role == "tank") then
			tank = name;
		end;
	end;
	
	CU:PartyMessage("Tank: " .. tank .. ". Healer: " .. healer .. ". Dps: " .. dpses);
end;

function GM:CheckIfGroupIsComplete()
	if(myDPSCount == 3 and myHealerCount == 1 and myTankCount == 1) then
		myIsSearching = nil;
		CU:PartyMessage("Group is full, lets get started!");
		self:PrintGroupRoles();
	end;
end

function GM:AddNewDps(aNewDps)
	if(myDPSCount < 3) then
		myParty[aNewDps] = "dps";
		myDPSCount = myDPSCount + 1;
		self:Print("New Member: " .. aNewDps .. " (dps)");
		CU:PartyMessage("New Member: " .. aNewDps .. " (dps)");
		self:CheckIfGroupIsComplete();
	else
		self:Print("Allready have 3 dps");
	end;
end

function GM:AddNewHealer(aNewHealer)
	if(myHealerCount == 0) then
		myParty[aNewHealer] = "healer";
		myHealerCount = myHealerCount + 1;
		self:Print("New Member: " .. aNewHealer .. " (healer)");
		CU:PartyMessage("New Member: " .. aNewHealer .. " (healer)");
		self:CheckIfGroupIsComplete();
	else
		self:Print("Allready have a healer");
	end;
end

function GM:AddNewTank(aNewTank)
	if(myTankCount == 0) then
		myParty[aNewTank] = "tank";
		myTankCount = myTankCount + 1;
		self:Print("New Member: " .. aNewTank .. " (tank)");
		CU:PartyMessage("New Member: " .. aNewTank .. " (tank)");
		self:CheckIfGroupIsComplete();
	else
		self:Print("Allready have a tank");
	end;
end

function GM:StartSearching(aInstanceName)
	if(myIsSearching == true) then
		self:Print("Allready searching! Instance: " .. myInstance);
		return;
	end;
	self:Print("Started search for: " .. aInstanceName);
	myIsSearching = true;
	myInstance = aInstanceName;
	myIsInstanceFinished = nil;
	
	GM:ScheduleEvent(PrintLFMMessage, 1);
end

function GM:StopSearching()
	myIsSearching = nil;
	self:Print("Search stopped.");
	CU:PartyMessage("Stopped looking for members.");
end;

function GM:FinishInstance()
	CU:PartyMessage("Instance is complete! Good job and thanks for joining everyone!");
	myIsInstanceFinished = true;
	myIsSearching = nil;
end

function GM:InviteDps(aDpsName)
	if(myDPSCount < 3) then
		InviteByName(aDpsName);
		if(myNotAddedMembers[aDpsName] == nil) then
			myNotAddedMembers[aDpsName] = "dps";
		end;
	else
		SendChatMessage("We are full on dps im affraid", "WHISPER", nil, aDpsName)
	end;
end

function GM:InviteHealer(aHealerName)
	if(myHealerCount == 0) then
		InviteByName(aHealerName);
		if(myNotAddedMembers[aHealerName] == nil) then
			myNotAddedMembers[aHealerName] = "healer";
		end;
	else
		SendChatMessage("We allready have a healer im affraid.", "WHISPER", nil, aHealerName)
	end;
end

function GM:InviteTank(aTankName)
	if(myTankCount == 0) then
		InviteByName(aTankName);
		if(myNotAddedMembers[aTankName] == nil) then
			myNotAddedMembers[aTankName] = "tank";
		end;
	else
		SendChatMessage("We allready have a tank im affraid.", "WHISPER", nil, aTankName)
	end;
end

function GM:AutoInvite(aName)
	if(myTankCount == 0 and myHealerCount == 1 and myDPSCount == 3) then
		self:InviteTank(aName);
	elseif(myTankCount == 1 and myHealerCount == 0 and myDPSCount == 3) then
		self:InviteHealer(aName);
	elseif(myTankCount == 1 and myHealerCount == 1 and myDPSCount < 3) then
		self:InviteDps(aName);
	elseif(myTankCount == 1 and myHealerCount == 1 and myDPSCount == 3) then
		SendChatMessage("We are full im affraid.", "WHISPER", nil, aName);
	else
		self:AskForRole(aName);
	end;
end

function GM:CHAT_MSG_WHISPER(message, author)
	if(myIsSearching == true) then
		if(string.len(message) >= 10) then
			self:Print("Filtered whisper, too long message: " .. message);
			return;
		end;

		if(string.find(message, "dps") ~= nil) then
			self:InviteDps(author);
		elseif (string.find(message, "tank") ~= nil) then
			self:InviteTank(author);
		elseif (string.find(message, "heal") ~= nil) then
			self:InviteHealer(author);
		elseif (string.find(message, "inv") ~= nil) then
			self:AutoInvite(author);
		end;
	end;
end

function GM:CHAT_MSG_PARTY(message, author)
	if(author ~= UnitName("player")) then
		self:Print("PartyMessage from: " .. author);
	end
end;

function GM:AddNewMember()
	for i=1, GetNumPartyMembers() do
		local partyMemberName = UnitName("party" .. i);
		
		if(myParty[partyMemberName] == nil) then
			local newRole = myNotAddedMembers[partyMemberName];

			if(newRole == "dps") then
				self:AddNewDps(partyMemberName);
			elseif(newRole == "healer") then
				self:AddNewHealer(partyMemberName);
			elseif(newRole == "tank") then
				self:AddNewTank(partyMemberName);
			end;
			
			myNotAddedMembers[partyMemberName] = nil;
		end;
	end;
end

function GM:FindThePersonWhoLeft()
	
	if(myIsInstanceFinished ~= nil) then
		return;
	end;
	
	local partyCopy = {};
	for orig_key, orig_value in pairs(myParty) do
		partyCopy[orig_key] = orig_value;
	end

	partyCopy[UnitName("player")] = nil;
	for i=1, GetNumPartyMembers() do
		local partyMemberName = UnitName("party" .. i);
		
		partyCopy[partyMemberName] = nil;
	end
	
	for name, role in pairs(partyCopy) do
		if(role == "dps") then
			myDPSCount = myDPSCount - 1;
		elseif(role == "tank") then
			myTankCount = myTankCount - 1;
		elseif(role == "healer") then
			myHealerCount = myHealerCount -1;
		end;
		myParty[name] = nil;
		
		if(myIsSearching == nil) then
			GM:ScheduleEvent(PrintLFMMessage, 1);
			myIsSearching = true;
		end;
		
		CU:PartyMessage(name .. " (" .. role .. ") left the group. Searching for replacement...");
		self:RegisterEvent("CHAT_MSG_WHISPER");
	end
	
	
	
	partyCopy = nil;
end

function GM:PARTY_MEMBERS_CHANGED()
	if(GetNumPartyMembers()+1 < myDPSCount + myHealerCount + myTankCount) then
		self:FindThePersonWhoLeft();
	else
		self:AddNewMember();
	end
end



function GM:CreateDewDropMenu()
	self.DewDrop = AceLibrary("Dewdrop-2.0");
	
	local dewMenu = {
		type='group',
		args = {
			addDps = {
				type = 'text',
				name = 'Add Dps',
				desc = 'Adds a new dps to the group',
				usage = "<Enter the name of the new dps>",
				set = "AddNewDps",
				get = false,
			},
			addHealer = {
				type = 'text',
				name = 'Add Healer',
				desc = 'Adds a new healer to the group',
				usage = "<Enter the name of the new healer>",
				set = "AddNewHealer",
				get = false,
			},
			addTank = {
				type = 'text',
				name = 'Add Tank',
				desc = 'Adds a new tank to the group',
				usage = "<Enter the name of the new tank>",
				set = "AddNewTank",
				get = false,
			},
			startSearch = {
				type = 'text',
				name = 'Start Search',
				desc = 'Starts a new search',
				usage = "<Enter the name of the instance>",
				set = "StartSearching",
				get = false,
			},
			stopSearch = {
				type = 'execute',
				name = 'Stop Search',
				desc = 'Stops the current search',
				func = function()
					GM:StopSearching();
				end;
			},
			finishInstance = {
				type = 'execute',
				name = 'Finish Instance',
				desc = 'Tells the addon that the instance has been finished',
				func = function()
					GM:FinishInstance();
				end;
			},
			printGroup = {
				type = 'execute',
				name = 'Print Group',
				desc = 'Prints name and role of each member to partychat',
				func = function()
					GM:PrintGroupRoles();
				end;
			},
		}
	}
	
	self.DewDrop:InjectAceOptionsTable(self, dewMenu);
	return dewMenu;
end;

function GM:InitMenu()
	if(not self.menu) then
		self.menu = GM:CreateDewDropMenu();
	end;
	
	local slashMenu = {
		type = "group",
		args = {
			config = {
				type = 'execute',
				name = 'Config',
				desc = 'Opens the config',
				func = function()
					self.DewDrop:Open(UIParent, 'children', function() self.DewDrop:FeedAceOptionsTable(self.menu) end, 'cursorX', true, 'cursorY', true);
				end;
			},
			startSearch = {
				type = 'text',
				name = 'Start Search',
				desc = 'Starts a new search',
				usage = "<Enter the name of the instance>",
				set = "StartSearching",
				get = false,
			},
			stopSearch = {
				type = 'execute',
				name = 'Stop Search',
				desc = 'Stops the current search',
				func = function()
					GM:StopSearching();
				end;
			},
		}
	}
	
	GM:RegisterChatCommand({"/partymanager", "/pm"}, slashMenu);
end;

function GM:OnEnable()
	self:RegisterEvent("PARTY_MEMBERS_CHANGED");
	self:RegisterEvent("CHAT_MSG_WHISPER");
	self:RegisterEvent("CHAT_MSG_PARTY");
	self:InitMenu();
end