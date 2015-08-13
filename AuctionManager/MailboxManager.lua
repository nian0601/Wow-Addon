local MM = AceLibrary("AceAddon-2.0"):new("AceConsole-2.0", "AceEvent-2.0");

MM.myMoneyCount = 0;
MM.myMailCount = 0;

function MM:DeleteMail(aMailIndex)
	DeleteInboxItem(aMailIndex);
	MM:ScheduleEvent(self.TakeAll, 1, self);
end;

function MM:TakeItems(aMailIndex, aMoney)
	local _, _, _, _, _, _, _, hasItem = GetInboxHeaderInfo(1);
	
	if (hasItem ~= nil) then
		TakeInboxItem(aMailIndex, 1);
		
		MM:ScheduleEvent(self.TakeItems, 1, self, aMailIndex);
	else
		self:DeleteMail(aMailIndex);
	end;
end;

function MM:GetGoldAmount()
	return math.floor(MM.myMoneyCount / 10000);
end;

function MM:GetSilverAmount(aGoldAmount)
	local remainder = MM.myMoneyCount - (aGoldAmount * 10000);
	
	return math.floor(remainder / 100);
end;

function MM:GetCopperAmount(aGoldAmount, aSilverAmount)
	local remainder = MM.myMoneyCount - (aGoldAmount * 10000);
	remainder = remainder - (aSilverAmount * 100);
	
	return remainder;
end;

function MM:PrintGoldAmount()
	local gold = self:GetGoldAmount();
	local silver = self:GetSilverAmount(gold);
	local copper = self:GetCopperAmount(gold, silver);
	
	self:Print("Retrived : " .. gold .."g " .. silver .. "s " .. copper .. "c.");
end;

function MM:TakeAll()
	if(GetInboxNumItems() == 0) then
		self:Print("");
		self:PrintGoldAmount();
		self:Print("Finished opening mails. Processed " .. self.myMailCount .. " mails.");
		return;
	end;

	self.myMailCount = self.myMailCount + 1;

	local _, _, sender, subject, money, _, _, hasItem = GetInboxHeaderInfo(1);
	
	if(sender == "Horde Auction House") then
		self:TriggerEvent("AuctionData_UpdateSalesData", subject, money);
		TakeInboxMoney(1);
		MM.myMoneyCount = MM.myMoneyCount + money;
		MM:ScheduleEvent(self.DeleteMail, 1, self, 1);
	else
		if(money > 0) then
			TakeInboxMoney(1);
			MM.myMoneyCount = MM.myMoneyCount + money;
			
			if(hasItem == nil) then
				MM:ScheduleEvent(self.DeleteMail, 1, self, 1);
				return;
			end;
		end;
		
		if(hasItem ~= nil) then
			MM:ScheduleEvent(self.TakeItems, 1, self, 1);
		end;
	end;
	
end;

function MM:InitMenu()
	local slashMenu = {
		type = "group",
		args = {
			takeAll = {
				type = 'execute',
				name = 'Take All',
				desc = 'Takes everything from the mailbox',
				func = function()
					self.myMoneyCount = 0;
					self.myMailCount = 0;
					self:TakeAll();
				end;
			},
		}
	}
	
	MM:RegisterChatCommand({"/mailbox", "/mb"}, slashMenu);
end;

function MM:OnEnable()
	self:InitMenu();
end