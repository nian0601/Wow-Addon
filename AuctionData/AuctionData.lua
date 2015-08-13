AuctionData = AceLibrary("AceAddon-2.0"):new("AceConsole-2.0", "AceDB-2.0", "AceEvent-2.0");
AuctionData:RegisterDB("AuctionDataDB", "AuctionDataDBPC");
AuctionData:RegisterDefaults("profile", {
	myItemTable = {},
	mySalesRecord = {},
	myPendingSales = {},
})

function AuctionData:OnEnable()
	self:RegisterEvent("AuctionData_PrintItemPrice", "PrintItemPrice");
	self:RegisterEvent("AuctionData_PrintSalesData", "PrintSalesData");
	self:RegisterEvent("AuctionData_WatchItem", "WatchItem");
	self:RegisterEvent("AuctionData_UnwatchItem", "UnwatchItem");
	self:RegisterEvent("AuctionData_ResetWatchList", "ResetWatchList");
	self:RegisterEvent("AuctionData_ResetAllPrices", "ResetAllPrices");
	self:RegisterEvent("AuctionData_UpdateItemPrice", "UpdateItemPrice");
	self:RegisterEvent("AuctionData_UpdateMinBid", "UpdateMinBid");
	self:RegisterEvent("AuctionData_UpdateMinBuyout", "UpdateMinBO");
	self:RegisterEvent("AuctionData_RegisterNewSalesItem", "RegisterNewSalesItem");
	self:RegisterEvent("AuctionData_UpdateSalesData", "UpdateSalesData");
	self:RegisterEvent("AuctionData_AddPendingSale", "AddPendingSale");
end;


--[[

	Resets all the variables used when querying, to prepare the addon for a new query i the future

]]--
function AuctionData:FinishQuerying()
	for name, info in pairs(self.db.profile.myItemTable) do
		self.db.profile.myItemTable[name].myQueryFinished = false;
		self.db.profile.myItemTable[name].myQueryStarted = false;
	end;	
end;


--[[

	Returns the entire ItemTable

]]--
function AuctionData:GetDataTable()

	return self.db.profile.myItemTable;
end;


--[[

	Resets all the variables used when posting, to prepare the addon for a new postaction i the future

]]--
function AuctionData:ResetPostingData()
	for name, info in pairs(self.db.profile.myItemTable) do
		self.db.profile.myItemTable[name].mySkipPosting = false;
	end;
end;


--[[

	Resets all the variables used when querying for one item, so that there is no old data when a query is performed

]]--
function AuctionData:ResetQueryData(aItemName)
	self.db.profile.myItemTable[aItemName].myQueryStarted = true;
	self.db.profile.myItemTable[aItemName].myMinBid = -1;
	self.db.profile.myItemTable[aItemName].myMinBO = -1;
end;


--[[

	Returns the infotable for a specific item

]]--
function AuctionData:GetItemTable(aItemName)

	return self.db.profile.myItemTable[aItemName];	
end;


--[[

	Returns the average bid for a specific item

]]--
function AuctionData:GetItemBid(aItemName)
	local info = self:GetItemTable(aItemName);

	if(info ~= nil) then
		return info.myBid;
	end;

	return nil;
end;


--[[

	Returns the average buyout for a specific item

]]--
function AuctionData:GetItemBuyout(aItemName)
	local info = self:GetItemTable(aItemName);

	if(info ~= nil) then
		return info.myBuyout;
	end;

	return nil;
end;


--[[

	Returns the minimum bid for a specific item

]]--
function AuctionData:GetItemMinBid(aItemName)
	local info = self:GetItemTable(aItemName);

	if(info ~= nil) then
		return info.myMinBid;
	end;

	return nil;
end;


--[[

	Returns the minimum buyout for a specific item

]]--
function AuctionData:GetItemMinBuyout(aItemName)
	local info = self:GetItemTable(aItemName);

	if(info ~= nil) then
		return info.myMinBO;
	end;

	return nil;
end;


--[[

	Prints the prices for a specific item into the DefaultChatFrame

]]--
function AuctionData:PrintItemPrice(aItemName)

	if(self.db.profile.myItemTable[aItemName] == nil) then
		self:Print("No Data for " .. aItemName);
	else

		local bid = self.db.profile.myItemTable[aItemName].myBid;
		local buyout = self.db.profile.myItemTable[aItemName].myBuyout;
		local minBid = self.db.profile.myItemTable[aItemName].myMinBid;
		local minBuyout = self.db.profile.myItemTable[aItemName].myMinBO;
		
		self:Print("Avg Bid: " .. CU:GetFullCurrency(bid) .. ", Min Bid: " .. CU:GetFullCurrency(minBid));
		self:Print("Avg Buyout: " .. CU:GetFullCurrency(buyout) .. ", Min Buyout: " .. CU:GetFullCurrency(minBuyout));
	end;
end;


--[[

	Prints the salesdata of a specific item into the DefaultChatFrame

]]--
function AuctionData:PrintSalesData(aItemName)
	if(self.db.profile.mySalesRecord[aItemName] == nil) then
		self:Print("No Data for " .. aItemName);
	else

		local successes = self.db.profile.mySalesRecord[aItemName].mySucessfulSales;
		local fails = self.db.profile.mySalesRecord[aItemName].myFailedSales;

		self:Print(aItemName .. ":");
		self:Print("Successful Sales: " .. successes .. ", (Avg Price: " .. CU:GetFullCurrency(self.db.profile.mySalesRecord[aItemName].myAvgPrice) .. ")");
		self:Print("Failed Sales: " .. fails);
	end;
end;


--[[

	Adds a item to the watchlist (items that gets queried/posted)

]]--
function AuctionData:WatchItem(aItem)
	if(self.db.profile.myItemTable[aItem] == nil) then
		self.db.profile.myItemTable[aItem] = {
			myBid = 0,
			myBuyout = 0,
			myDataCount = 0,
			myMinBid = -1,
			myMinBO = -1,
			myQueryStarted = false,
			myQueryFinished = false,
			mySkipPosting = false,
		};

		self:Print("Added new item to Watch-list: " .. aItem);
	end;
end;


--[[

	Removes a item from the watchlist (items that gets queried/posted)

]]--
function AuctionData:UnwatchItem(aItem)
	if(self.db.profile.myItemTable[aItem] ~= nil) then
		self.db.profile.myItemTable[aItem] = nil;
		self:Print("Removed item from Watch-list: " .. aItem);
	end;
end;


--[[

	Clears the watchlist (items that gets queried/posted), NOT REVERSABLE

]]--
function AuctionData:ResetWatchList()
	for name, _ in pairs(self.db.profile.myItemTable) do
		self:UnwatchItem(name);
	end;
end;


--[[

	Resets all the prices gathered by the addon, used to clear out corrupt data, NOT REVERSABLE

]]--
function AuctionData:ResetAllPrices()
	for key, _ in pairs(self.db.profile.myItemTable) do
		self.db.profile.myItemTable[key].myBid = 0;
		self.db.profile.myItemTable[key].myBuyout = 0;
		self.db.profile.myItemTable[key].myMinBid = 0;
		self.db.profile.myItemTable[key].myMinBO = 0;
		self.db.profile.myItemTable[key].myDataCount = 0;
	end;
	
	self:Print("");
	self:Print("All prices reset to 0");
end;


--[[

	Updates the average bid and buyout for a specific item. Used while querying

]]--
function AuctionData:UpdateItemPrice(aItem, aBid, aBuyout, aStackSize)	
	local bidPerUnit = aBid / aStackSize;
	local buyoutPerUnit = aBuyout / aStackSize;
	
	if(self.db.profile.myItemTable[aItem].myBid == nil) then
		self.db.profile.myItemTable[aItem].myBid = bidPerUnit;
	end;
	
	if(self.db.profile.myItemTable[aItem].myBuyout == nil) then
		self.db.profile.myItemTable[aItem].myBuyout = buyoutPerUnit
	end;
	
	local baseBid = self.db.profile.myItemTable[aItem].myBid * self.db.profile.myItemTable[aItem].myDataCount;
	local baseBuyout = self.db.profile.myItemTable[aItem].myBuyout * self.db.profile.myItemTable[aItem].myDataCount;
	
	local newBid = baseBid + bidPerUnit;
	local newBuyout = baseBuyout + buyoutPerUnit;
	
	self.db.profile.myItemTable[aItem].myDataCount = self.db.profile.myItemTable[aItem].myDataCount + 1;
	self.db.profile.myItemTable[aItem].myBid = math.floor(newBid / self.db.profile.myItemTable[aItem].myDataCount);
	self.db.profile.myItemTable[aItem].myBuyout = math.floor(newBuyout / self.db.profile.myItemTable[aItem].myDataCount);
end;


--[[

	Updates the min bid for a specific item. Used while querying

]]--
function AuctionData:UpdateMinBid(aItem, aCost, aStackSize)
	if(aCost > 0) then
		--Calculate Bid price per item
		local costPerUnit = aCost / aStackSize;
		
		--Save down the minbid (for easier use)
		local curMinBid = self.db.profile.myItemTable[aItem].myMinBid;
		
		if(curMinBid == -1 or costPerUnit < curMinBid) then
			 self.db.profile.myItemTable[aItem].myMinBid = math.floor(costPerUnit);
		end;

	end;
end;


--[[

	Updates the min buyout for a specific item. Used while querying

]]--
function AuctionData:UpdateMinBO(aItem, aCost, aStackSize)
	if(aCost > 0) then
		--Calculate Buyout price per item
		local costPerUnit = aCost / aStackSize;
		
		--Save down the minBO (for easier use)
		local curMinBO = self.db.profile.myItemTable[aItem].myMinBO;
		
		if(curMinBO == -1 or costPerUnit < curMinBO) then
			 self.db.profile.myItemTable[aItem].myMinBO = math.floor(costPerUnit);
		end;

	end;
end;


--[[

	Adds a new entry into the SalesRecord table

]]--
function AuctionData:RegisterNewSalesItem(aItem)
	self.db.profile.mySalesRecord[aItem] = {
		mySucessfulSales = 0,
		myFailedSales = 0,
		myAvgPrice = 0,
	};
	
	self:Print("Registered new item: " .. aItem);
end;


--[[

	Updates the SalesData when recieving a mail from the auctionhouse, NOT WORKING PROPERLY

]]--
function AuctionData:UpdateSalesData(aMailSubject, aMoneyAmount)

	local item = nil;
	local auctionType = nil;
	
	local startIndex, endIndex = string.find(aMailSubject, "Auction successful: ");

	if(startIndex ~= nil and endIndex ~= nil) then
		auctionType = "sale";
	else
		startIndex, endIndex = string.find(aMailSubject, "Auction expired: ");
		if(startIndex ~= nil and endIndex ~= nil) then
			auctionType = "fail";
		else
			startIndex, endIndex = string.find(aMailSubject, "Auction won: ");
			if(startIndex ~= nil and endIndex ~= nil) then
				auctionType = "won";
			end;
		end;
	end;
	
	if(auctionType ~= nil) then
		item = string.sub(aMailSubject, endIndex + 1, string.len(aMailSubject))
		
		if(self.db.profile.mySalesRecord[item] == nil) then
			self:RegisterNewSalesItem(item);
		end;
		
		if(auctionType == "sale") then
			if(self.db.profile.myPendingSales[aItem] ~= nil and self.db.profile.myPendingSales[aItem][aMoneyAmount] ~= nil) then
				local newTotal = (self.db.profile.mySalesRecord[item].myAvgPrice * self.db.profile.mySalesRecord[item].mySucessfulSales) + self.db.profile.myPendingSales[aItem][aMoneyAmount].myPricePerUnit;
				self.db.profile.mySalesRecord[item].mySucessfulSales = self.db.profile.mySalesRecord[item].mySucessfulSales + 1;
				self.db.profile.mySalesRecord[item].myAvgPrice = newTotal / self.db.profile.mySalesRecord[item].mySucessfulSales;
				
				self.db.profile.myPendingSales[aItem][aMoneyAmount].myCount = self.db.profile.myPendingSales[aItem][aMoneyAmount].myCount - 1;
				
				if(self.db.profile.myPendingSales[aItem][aMoneyAmount].myCount == 0) then
					self.db.profile.myPendingSales[aItem][aMoneyAmount] = nil;
				end;
				
				self:Print("Sold: " .. item .. ", updating price");
			end;
		elseif (auctionType == "fail") then
			self.db.profile.mySalesRecord[item].myFailedSales = self.db.profile.mySalesRecord[item].myFailedSales + 1;
		elseif (auctionType == "won") then
			TakeInboxItem(1, 1);
		end;
	end;
end;


--[[

	Registers a pending sale, used when posting auctions. Used to keep track of sucessful sales and track prices of sales etc

]]--
function AuctionData:AddPendingSale(aItem, aBuyout, aStackSize)
	local priceAfterAHCut = math.floor(aBuyout * 0.95);

	if(self.db.profile.myPendingSales[aItem] == nil) then
		self.db.profile.myPendingSales[aItem] = {};
	end;
	
	if(self.db.profile.myPendingSales[aItem][priceAfterAHCut] == nil) then
		self.db.profile.myPendingSales[aItem][priceAfterAHCut] = {
			myCount = 1,
			myPricePerUnit = math.floor(priceAfterAHCut / aStackSize),
		};
	else
		self.db.profile.myPendingSales[aItem][priceAfterAHCut].myCount = self.db.profile.myPendingSales[aItem][priceAfterAHCut].myCount + 1;
	end;
end