local CR = AceLibrary("AceAddon-2.0"):new("AceConsole-2.0", "AceEvent-2.0");


function CR:OnEnable()
	self:RegisterEvent("CHAT_MSG_WHISPER");
end;



function CR:Checkmoney(aAuthor, aMsg)
	if(aMsg == "Checkmoney") then
		local totalMoney = CU:GetFullCurrency(GetMoney());

		SendChatMessage("There is " .. totalMoney .. " in the bank.", "WHISPER", nil, aAuthor);
	end;
end;

function CR:Pricecheck(aAuthor, aMsg)
	local item = nil;
	local stackSize = 1;
	local startIndex, endIndex = string.find(aMsg, "%[(.*)%]");
	if(startIndex ~= nil and endIndex ~= nil) then
		item = string.sub(aMsg, startIndex+1, endIndex-1);
	end;

	if(item == "ITEMLINK") then
		return;
	end;

	startIndex, endIndex = string.find(aMsg, "%]%s(%d+)")
	if(startIndex ~= nil and endIndex ~= nil) then
		stackSize = tonumber(string.sub(aMsg, startIndex+1, endIndex));
	end;


	if(item == nil) then
		SendChatMessage("Failed itemlink, try again.", "WHISPER", nil, aAuthor);
		return;
	end;

	local buyout = AuctionData:GetItemBuyout(item) * stackSize;
	local bid = AuctionData:GetItemBid(item) * stackSize;
	local dataCount = AuctionData:GetItemDataCount(item);

	if((buyout == nil or buyout == 0) or (bid == nil or bid == 0)) then
		SendChatMessage("No price registered for " .. item .. ".", "WHISPER", nil, aAuthor);
		self:TriggerEvent("AuctionData_WatchItem", item);
		return;
	end;

	SendChatMessage(item .. " (" .. stackSize .. "), Seen " .. dataCount .. " times. ", "WHISPER", nil, aAuthor);
	SendChatMessage("Avg Bid: " .. CU:GetFullCurrency(bid), "WHISPER", nil, aAuthor);
	SendChatMessage("Avg Buyout: " .. CU:GetFullCurrency(buyout), "WHISPER", nil, aAuthor);

	self:Print(item);
end;

function CR:PrintCommands(aAuthor, aMsg)
	if(aMsg == "Commands") then
		SendChatMessage("Commands:", "WHISPER", nil, aAuthor);
		SendChatMessage("Checkmoney (returns the amount of money in bank)", "WHISPER", nil, aAuthor);
		SendChatMessage("Pricecheck [ITEMLINK] STACKSIZE (returns avg bid and buyout for an item)", "WHISPER", nil, aAuthor);
	end;
end;

local functionTable = {
	Checkmoney = function(aAuthor, aMsg) CR:Checkmoney(aAuthor, aMsg) end,
	Pricecheck = function(aAuthor, aMsg) CR:Pricecheck(aAuthor, aMsg) end,
	Commands = function(aAuthor, aMsg) CR:PrintCommands(aAuthor, aMsg) end,
}

function CR:CHAT_MSG_WHISPER(aMsg, aAuthor)
	for command, func in pairs(functionTable) do
		local first, last = string.find(aMsg, command);
		if(first ~= nil and last ~= nil) then
			func(aAuthor, aMsg);
		end;
	end
end;
