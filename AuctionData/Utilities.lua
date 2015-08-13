CU = {};

function CU.PartyMessage(aMessage)
	if(aMessage ~= nil) then
		SendChatMessage("[GroupManager]: " .. aMessage, "PARTY");
	end;
end;

function CU.WorldMessage(aMessage)
	if(aMessage ~= nil) then
		SendChatMessage(aMessage, "CHANNEL", nil, GetChannelName("World"));
	end;
end;

function CU.GetFullCurrency(aCopperAmount)
	local amount = aCopperAmount;
	local gold = 0;
	local silver = 0;
	local copper = 0;
	
	
	if(amount >= 10000) then
		gold = math.floor(amount / 10000);
		amount = amount - math.floor(gold * 10000);
	end;
	
	if(amount >= 100) then
		silver = math.floor(amount / 100);
		amount = amount - math.floor(silver * 100);
	end;
	
	copper = amount;
	
	
	local returnMsg = gold .. "g " .. silver .. "s " .. copper .. "c";
	return returnMsg;
end;

function CU.ConvertToCopper(aGold, aSilver, aCopper)
	return (aGold * 10000) + (aSilver * 100) + aCopper;
end;