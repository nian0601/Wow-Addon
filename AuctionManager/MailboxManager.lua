local MM = AceLibrary("AceAddon-2.0"):new("AceConsole-2.0", "AceEvent-2.0");

MM.myMoneyCount = 0;
MM.myMailCount = 0;


--[[

	Deletes the mail from the given inbox-index

]]--
function MM:DeleteMail(aMailIndex)
	DeleteInboxItem(aMailIndex);
	MM:ScheduleEvent(self.TakeAll, 1, self);
end;

--[[

	Returns the goldamount

]]--
function MM:GetGoldAmount()

	return math.floor(MM.myMoneyCount / 10000);
end;


--[[

	Returns the silveramount

]]--
function MM:GetSilverAmount(aGoldAmount)
	local remainder = MM.myMoneyCount - (aGoldAmount * 10000);
	
	return math.floor(remainder / 100);
end;


--[[

	Returns the copperamount

]]--
function MM:GetCopperAmount(aGoldAmount, aSilverAmount)
	local remainder = MM.myMoneyCount - (aGoldAmount * 10000);
	remainder = remainder - (aSilverAmount * 100);
	
	return remainder;
end;


--[[

	Prints how much money was retrived from the mailbox

]]--
function MM:PrintGoldAmount()
	local gold = self:GetGoldAmount();
	local silver = self:GetSilverAmount(gold);
	local copper = self:GetCopperAmount(gold, silver);
	
	self:Print("Retrived : " .. gold .."g " .. silver .. "s " .. copper .. "c.");
end;


--[[

	Handles mails from sucessful auctionsales

]]--
function MM:ProcessSucessfulSale(aItem, aMoney)
	AuctionData:UpdateSucessfulSale(aItem, aMoney);
	TakeInboxMoney(1);
end;


--[[

	Handles mails from failed auctions

]]--
function MM:ProcessFailedSale(aItem, aMoney)
	AuctionData:UpdateFailedSale(aItem, aMoney);
	TakeInboxItem(1, 1);
end;


--[[

	Handles won auctions

]]--
function MM:ProcessWonAuction()
	TakeInboxItem(1, 1);
end;

--[[

	Handles mails comming from the auctionhouse
	Realy only figures out if the mail is from a sucessful sale, a failed sale or from a won auction and then redirect to the appropriate function

]]--
function MM:ProcessAuctionMail(aSubject, aMoney)
	local item = nil;

	local startIndex, endIndex = string.find(aSubject, "Auction successful: ");
	

	if(startIndex ~= nil and endIndex ~= nil) then
		item = string.sub(aSubject, endIndex + 1, string.len(aSubject))
		self:ProcessSucessfulSale(item, aMoney);
		return;
	end;

	startIndex, endIndex = string.find(aSubject, "Auction expired: ");
	if(startIndex ~= nil and endIndex ~= nil) then
		item = string.sub(aSubject, endIndex + 1, string.len(aSubject))
		self:ProcessFailedSale(aItem);
		return;
	end;

	startIndex, endIndex = string.find(aSubject, "Auction won: ");
	if(startIndex ~= nil and endIndex ~= nil) then
		self:ProcessWonAuction();
		return ;
	end;
end;


--[[

	Opens all mails, takeing all the money and all the items

]]--
function MM:TakeAll()
	if(GetInboxNumItems() == 0) then
		self:Print("");
		self:PrintGoldAmount();
		self:Print("Finished opening mails. Processed " .. self.myMailCount .. " mails.");
		return;
	end;

	self.myMailCount = self.myMailCount + 1;

	GetInboxText(1);
	local _, _, sender, subject, money, _, _, hasItem = GetInboxHeaderInfo(1);
	
	if(sender == "Horde Auction House") then
		self:Print("Processing Auction mail...");
		self:ProcessAuctionMail(subject, money);
	else
		if(hasItem > 0) then
			TakeInboxItem(1, 1);
		end;

		TakeInboxMoney(1);
	end;

	MM.myMoneyCount = MM.myMoneyCount + money;
	MM:ScheduleEvent(self.DeleteMail, 1, self, 1);
end;


--[[

	Constructs the very configmenu

]]--
function MM:InitMenu()
	local slashMenu = {
		type = "group",
		args = {
			takeAll = {
				type = 'execute',
				name = 'Take All',
				desc = 'Takes everything from the mailbox',
				func = function()
					CheckInbox();
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