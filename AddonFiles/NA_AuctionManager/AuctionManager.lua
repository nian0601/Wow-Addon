
local AM = AceLibrary("AceAddon-2.0"):new("AceConsole-2.0", "AceEvent-2.0", "AceDB-2.0");
AM:RegisterDB("AuctionManagerDB");
AM:RegisterDefaults("profile", {
	myUnderCutPercent = 0.95,
	myAvgPriceModifier = 1,
	myIsUnderCutting = false,
	myPostCount = 0,
})

--[[

	Checks if the player has a given item in his/her inventory

]]--
function AM:DoesInventoryContainItem(aItemName)
	for bag = 0, NUM_BAG_SLOTS do
		for slot = 1, GetContainerNumSlots(bag) do
			
			local name = self:GetItemInfo(bag, slot);
			
			if(name ~= nil and name == aItemName) then
				return true;
			end;
		end;
	end;
	return false;
end;


--[[

	Returns itemName, maxStack and itemCount for an item in a given bag and bagslot

]]--
function AM:GetItemInfo(aBagID, aBagSlot)

	local link = GetContainerItemLink(aBagID, aBagSlot);
	if(link ~= nil) then
		local _, _, itemLink = string.find(link,"(item:%d+)");	
		
		local name, _, _, _, _, _, _, maxStack = GetItemInfo(itemLink);
		local _, itemCount = GetContainerItemInfo(aBagID, aBagSlot);
		
		return name, maxStack, itemCount;
	end;
	
	return nil, nil, nil;
end;


--[[

	Searches for the first of a given item in the players inventory. If the item is found the bag and bagslot is returned

]]--
function AM:FindFirstOfItem(aItemName)
	for bag = 0, NUM_BAG_SLOTS do
		for slot = 1, GetContainerNumSlots(bag) do
			local name = self:GetItemInfo(bag, slot);
			
			if(name ~= nil and name == aItemName) then
				return bag, slot;
			end;
		end;
	end;
	
	return nil, nil;
end;


--[[

	Searches for the given item in the players inventory, starting from the given bag and bagslot. If the item is found the bag and bagslot is returned

]]--
function AM:FindNextOfItem(aItem, aStartBag, aStartSlot)
	local startBag = aStartBag;
	local startSlot = aStartSlot + 1;
	
	if(startSlot > GetContainerNumSlots(startBag)) then
		startSlot = 1;
		startBag = startBag + 1;
	end;
	
	if(startBag > NUM_BAG_SLOTS) then
		return nil, nil;
	end;

	for bag = startBag, NUM_BAG_SLOTS do
		for slot = startSlot, GetContainerNumSlots(bag) do
			local name = self:GetItemInfo(bag, slot);
			
			if(name ~= nil and name == aItem) then
				return bag, slot;
			end;
		end;
	end;
	
	return nil, nil;
end;


--[[

	Finds the first bag that has an empty slot, if one is found the bagid is returned

]]--
function AM:GetFirstBagWithEmptySlot()
	for bag = 0, NUM_BAG_SLOTS do
		for slot = 1, GetContainerNumSlots(bag) do
			local link = GetContainerItemLink(bag, slot);
			if(link == nil) then
				return 19 + bag;
			end;
		end;
	end;
	
	return nil;
end;


--[[

	Finds the first free slot in the players inventory, if one is found the bag and bagslot is returned

]]--
function AM:GetFirstFreeSlot()
	for bag = 0, NUM_BAG_SLOTS do
		for slot = 1, GetContainerNumSlots(bag) do
			local link = GetContainerItemLink(bag, slot);
			if(link == nil) then
				return bag, slot;
			end;
		end;
	end;
	
	return nil, nil;
end;


--[[

	Starts an auction with the given item and prices

]]--
function AM:PlaceAuction(aItem, aBagID, aBagSlot, aStackSize, aBidPerUnit, aBOPerUnit, aCallBackFunction)

	PickupContainerItem(aBagID, aBagSlot);
	ClickAuctionSellItemButton();
	local bid = aBidPerUnit * aStackSize;
	local buyout = aBOPerUnit * aStackSize;
	
	self.db.profile.myPostCount = self.db.profile.myPostCount + 1;
	
	if(bid == nil or bid == 0) then
		bid = math.floor(buyout * 0.75);
	end;
	
	local deposit = CalculateAuctionDeposit(480);
	local ahCut = math.floor(buyout * 0.05);
	
	StartAuction(bid, buyout, 480);
	self:TriggerEvent("AuctionData_AddPendingSale", aItem, buyout, deposit, ahCut, aStackSize);
	AM:ScheduleEvent(self.PostAuctions, 1, self, aItem, aBidPerUnit, aBOPerUnit, aCallBackFunction);
end;


--[[

	Finds an item that should be posted to the AuctionHouse and Schedules a PlaceAuction-action

]]--
function AM:PostAuctions(aItem, aBidPerUnit, aBOPerUnit, aCallBackFunction)
	local bag, slot = self:FindFirstOfItem(aItem);
	
	if(bag ~= nil and slot ~= nil and aItem ~= nil) then
		local _, itemCount = GetContainerItemInfo(bag, slot);
		
		AM:ScheduleEvent(self.PlaceAuction, 1, self, aItem, bag, slot, itemCount, aBidPerUnit, aBOPerUnit, aCallBackFunction);
	else
		if(aCallBackFunction ~= nil) then
			AM:ScheduleEvent(aCallBackFunction, 3, self);
		else
			self:Print("");
			self:Print("Stopped posting " .. aItem .. ". Dont have any in the inventoy.");
		end;
	end;
end;


--[[

	Loops over all the instances of the given item in the current auctionhouse page and updates the data for that item
	using the bid and buyout found.
	When all the instances has been checked QueryAH is Scheduled to query the next page

]]--
function AM:CalcAveragePrice(aItem, aPage)
	local batch, count = GetNumAuctionItems("list");
	
	for i = 1, batch do
		local name, texture, count, quality, canUse, level, minBid, minIncrement, buyoutPrice, bidAmount, highestBidder, owner, sold = GetAuctionItemInfo("list", i)
			
		if(name == aItem) then
		
			self:TriggerEvent("AuctionData_UpdateItemPrice", aItem, minBid, buyoutPrice, count);
			self:TriggerEvent("AuctionData_UpdateMinBid", aItem, minBid, count);
			self:TriggerEvent("AuctionData_UpdateMinBuyout", aItem, buyoutPrice, count);
		end;
	end;
	
	if(batch < 50) then
		
		AuctionData.db.profile.myItemTable[aItem].myQueryFinished = true;
		self:Print("");
		self:Print("Finished Querying " .. aItem);
		
		self:TriggerEvent("AuctionData_PrintItemPrice", aItem);
		
		return;
	end;
	
	AM:ScheduleEvent(self.QueryAH, 0.5, self, aItem, aPage + 1);
end;


--[[

	Tries to query the given page, if it cant then it Schedules a callback to itself until it can.
	Once the query is sucessful CalcAveragePrice is Scheduled.

]]--
function AM:QueryAH(aItem, aPage)
	local canQuery = CanSendAuctionQuery();
	
	if(canQuery == 1) then
		self:Print(aItem .. ", Page: " .. aPage);
		QueryAuctionItems(aItem, 0, 0, 0, 0, 0, aPage, 0, 0, 1);
		AM:ScheduleEvent(self.CalcAveragePrice, 1, self, aItem, aPage);
	else
		AM:ScheduleEvent(self.QueryAH, 0.5, self, aItem, aPage);
	end;
end;


--[[

	Starts the querying of a single item, simply checks if the item is in the watchlist and Schedules QueryAH if is

]]--
function AM:QueryItem(aItem)
	if(AuctionData:GetItemTable(aItem) ~= nil) then
		AuctionData:ResetQueryData(aItem);
		self:Print("");
		self:Print("Querying " .. aItem .. "...");
		self:QueryAH(aItem, 0);
	end;
end;


--[[

	Queries an entire table of items, same principle as QueryItem, exept that it also Schedules a callback to itself while an item is being processed,
	until that item finishes, then moves on the next item

]]--
function AM:QueryItemTable(aTable)
	for name, _ in pairs(aTable) do
	
		local info = AuctionData:GetItemTable(name);
		if(info ~= nil) then
			if(info.myQueryStarted == false) then
				self:Print("");
				self:Print("Started Querying " .. name);
				AuctionData:ResetQueryData(name);
				self:QueryAH(name, 0);
				self:ScheduleEvent(self.QueryItemTable, 2, self, aTable);
				return;
			end
			
			if(info.myQueryFinished == false) then
				self:ScheduleEvent(self.QueryItemTable, 2, self, aTable);
				return;
			end;
		else
			self:Print(name .. " is not in Watch-list, skipping.");
		end;
		
	end;
	
	self:Print("");
	self:Print("Querying finished.");
	
	AuctionData:FinishQuerying();
end;


--[[

	Goes over the players inventory and adds all items thats also in the watchlist to a table that can be used for querying

]]--
function AM:GetInventoryAsQueryTable()
	local inv = {};

	for bag = 0, NUM_BAG_SLOTS do
		for slot = 1, GetContainerNumSlots(bag) do
		
			local itemName = self:GetItemInfo(bag, slot);
			if(itemName ~= nil and inv[itemName] == nil and AuctionData:GetItemTable(itemName) ~= nil) then
				inv[itemName] = {};
			end;
		end;
	end;

	AuctionData:FinishQuerying();
	
	return inv;
end;


--[[

	Goes over the players inventory and adds all items to the watchlist

]]--
function AM:WatchAllItemsInBag()
	for bag = 0, NUM_BAG_SLOTS do
		for slot = 1, GetContainerNumSlots(bag) do
			
			local name = self:GetItemInfo(bag, slot);
			
			if(name ~= nil) then
				self:TriggerEvent("AuctionData_WatchItem", name);
			end;
		end;
	end;
end;


--[[

	Posts a item using the Min Buyout that Querying found, to make sure that it realy is the 
	lowest price (for undercutting) the price is then multiplied by a modifier thats defined in the top.

]]--
function AM:PostItemUsingUndercut(aItem)
	local bid = AuctionData:GetItemMinBid(aItem);
	local buyout = AuctionData:GetItemMinBuyout(aItem);
	
	
	if(bid ~= nil and bid > 0 and buyout ~= nil and buyout > 0) then

		bid = math.floor((buyout * 0.75) * self.db.profile.myUnderCutPercent);
		buyout = math.floor(buyout * self.db.profile.myUnderCutPercent);

		self:Print("");
		self:Print("Posting: " .. aItem);
		self:Print("Bid: " .. CU:GetFullCurrency(bid));
		self:Print("Buyout: " .. CU:GetFullCurrency(buyout));
		
		AM:ScheduleEvent(self.PostAuctions, 1, self, aItem, bid, buyout, self.AutoPostEverything);
		return true;
	else
		self:Print("");
		self:Print("Dint find prices for " .. aItem .. ", skipping it");
		AuctionData.db.profile.myItemTable[aItem].mySkipPosting = true;
	end;
	
	return nil;
end;


--[[

	Posts a item using the Average Buyout that Querying found

]]--
function AM:PostItemUsingAvgPrice(aItem)
	local bid = AuctionData:GetItemBid(aItem);
	local buyout = AuctionData:GetItemBuyout(aItem);
	
	if(bid ~= nil and bid > 0 and buyout ~= nil and buyout > 0) then
		
		bid = math.floor(bid * self.db.profile.myAvgPriceModifier);
		buyout = math.floor(buyout * self.db.profile.myAvgPriceModifier);
		
		
		self:Print("");
		self:Print("Posting: " .. aItem);
		self:Print("Bid: " .. CU:GetFullCurrency(bid));
		self:Print("Buyout: " .. CU:GetFullCurrency(buyout) );
		
		AM:ScheduleEvent(self.PostAuctions, 1, self, aItem, bid, buyout, self.AutoPostEverything);
		return true;
	else
		self:Print("");
		self:Print("Dint find prices for " .. aItem .. ", skipping it");
		AuctionData.db.profile.myItemTable[aItem].mySkipPosting = true;
	end;
	
	return nil;
end;


--[[

	Loops over all the items in the watchlist, if that item is also found the players inventory then its posted.
	Based on the myIsUnderCutting variable the posting uses either Undercuting of AveragePricing.

]]--
function AM:AutoPostEverything()
	for name, info in pairs(AuctionData:GetDataTable()) do
		if(self:DoesInventoryContainItem(name) == true and AuctionData.db.profile.myItemTable[name].mySkipPosting == false) then
			local posted = nil;
			if(self.db.profile.myIsUnderCutting == true) then
				posted = self:PostItemUsingUndercut(name);
			else
				posted = self:PostItemUsingAvgPrice(name);
			end;
			
			if(posted ~= nil) then
				return
			end;
			
		end;
	end;
	
	self:Print("Finished posting, posted " .. self.db.profile.myPostCount .. " auction.");
	
	AuctionData:ResetPostingData();
	self.db.profile.myPostCount = 0;
end;


--[[

	Opens the Auctions-tab in the auctionhouse and then closes it agian.
	If the tab hasnt been shown before you start posting auctions it produces errors

]]--
function AM:ToggleAuctionsPage()
	if(AuctionFrameAuctions:IsVisible() == false) then
		AuctionFrameAuctions:Show();
		AuctionFrameAuctions:Hide();
	end;
end;




----------------------
---   MENU SETUP   ---
----------------------

--[[

	Constructs the DewDropmenu

]]--
function AM:CreateDewDropMenu()
	self.DewDrop = AceLibrary("Dewdrop-2.0");
	
	local dewMenu = {
		type='group',
		args = {
			post = {
				type = 'group',
				name = 'Post',
				desc = 'Post your item',
				args = {
					autoPostEverythingAvg =  {
						type = 'execute',
						name = 'Auto Post Everything (Avg Price)',
						desc = 'Posts everything from the Watch-list using average prices',
						func = function()
							self.db.profile.myPostCount = 0;
							self:ToggleAuctionsPage();
							self.db.profile.myIsUnderCutting = false;
							self:AutoPostEverything();
						end;
					},
					autoPostEverythingUndercut =  {
						type = 'execute',
						name = 'Auto Post Everything (Undercut)',
						desc = 'Posts everything from the Watch-list and undercutting the cheapest auction by 5%. Recommended to have a fresh query.',
						func = function()
							self.db.profile.myPostCount = 0;
							self:ToggleAuctionsPage();
							self.db.profile.myIsUnderCutting = true;
							self:AutoPostEverything();
						end;
					},
				}
			},
			queryItem = {
				type = 'text',
				name = 'Query Item',
				desc = 'Queries one item',
				usage = 'Querys one item. The item need to be in the Watch-list before it can be queried.',
				get = false,
				set = function(newValue)
					self:QueryItem(newValue);
				end,
			},
			queryAllItems = {
				type = 'execute',
				name = 'Query All Items',
				desc = 'Queries all Watched items',
				func = function()
					self:QueryItemTable(AuctionData:GetDataTable());
				end;
			},
			queryInventory = {
				type = 'execute',
				name = 'Query Inventory',
				desc = 'Queries all watched items in the inventory',
				func = function()
					self:QueryItemTable(self:GetInventoryAsQueryTable());
				end;
			},
			resetAllPrices = {
				type = 'execute',
				name = 'Reset ALL Prices',
				desc = 'Resets all prices, NOT REVERSABLE.',
				func = function()
					self:TriggerEvent("AuctionData_ResetAllPrices");
				end;
			},
			watchAllItemsInBag = {
				type = 'execute',
				name = 'Add Iventory to Watch-list',
				desc = 'Goes through all the items in the inventory and ads it to the Watch-list.',
				func = function()
					self:WatchAllItemsInBag();
				end;
			},
			resetWatchList = {
				type = 'execute',
				name = 'Reset Watch-list',
				desc = 'Resets the Watch-list, NOT REVERSABLE.',
				func = function()
					self:TriggerEvent("AuctionData_ResetWatchList", newValue);
				end;
			},
			printItem = {
				type = 'text',
				name = 'Print Item',
				desc = 'Prints information about a item',
				usage = '',
				get = false,
				set = function(newValue)
					self:TriggerEvent("AuctionData_PrintItemPrice", newValue);
				end,
			},
			printSalesData = {
				type = 'text',
				name = 'Print SalesInfo',
				desc = 'Prints salesinformation about a item',
				usage = '',
				get = false,
				set = function(newValue)
					self:TriggerEvent("AuctionData_PrintSalesData", newValue);
				end,
			},
			watchItem = {
				type = 'text',
				name = 'Watch Item',
				desc = 'Adds an item to the Watch-list',
				usage = '',
				get = false,
				set = function(newValue)
					self:TriggerEvent("AuctionData_WatchItem", newValue);
				end,
			},
			
		}
	}
	
	self.DewDrop:InjectAceOptionsTable(self, dewMenu);
	return dewMenu;
end;


--[[

	Registers the chatcommand and binds the dewdropmenu

]]--
function AM:InitMenu()
	if(not self.menu) then
		self.menu = AM:CreateDewDropMenu();
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
		}
	}
	
	AM:RegisterChatCommand({"/auctionmanager", "/am"}, slashMenu);
end;

function AM:OnEnable()
	
	self:InitMenu();
end