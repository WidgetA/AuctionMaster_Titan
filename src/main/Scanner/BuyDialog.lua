--[[
	Copyright (C) Udorn (Blackhand)

	This program is free software; you can redistribute it and/or
	modify it under the terms of the GNU General Public License
	as published by the Free Software Foundation; either version 2
	of the License, or (at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program; if not, write to the Free Software
	Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
--]]

--[[
	Asks the user for confirmation to buy a list of auctions.
--]]
vendor.BuyDialog = {}
vendor.BuyDialog.prototype = {}
vendor.BuyDialog.metatable = {__index = vendor.BuyDialog.prototype}

local log = vendor.Debug:new("BuyDialog")

local L = vendor.Locale.GetInstance()

local FRAME_HEIGHT = 300
local FRAME_WIDTH = 450
local TABLE_WIDTH = FRAME_WIDTH - 10
local TABLE_HEIGHT = FRAME_HEIGHT - 45
local TABLE_X_OFF = 5
local TABLE_Y_OFF = -40

--[[
	Wait until the user made a decison.
--]]
local function _WaitForDecision(self)
	while (not self.decisionMade) do
		coroutine.yield()
	end
end

-- [Titan Migration] 停止监听购买结果事件
local function _UnregisterBuyEvents(self)
	if self.eventFrame then
		self.eventFrame:UnregisterEvent("CHAT_MSG_SYSTEM")
		self.eventFrame:UnregisterEvent("UI_ERROR_MESSAGE")
	end
	self.pendingBuy = nil
end

-- [Titan Migration] 从搜索列表中移除已购买的行
local function _RemovePendingRow(self)
	if self.searchItemModel and self.pendingBuy and self.pendingBuy.row then
		-- row 号可能因之前的移除而偏移，需要通过 index 匹配找到当前位置
		local targetIndex = self.pendingBuy.index
		local model = self.searchItemModel
		for i = 1, #model.index do
			if model.index[i].index == targetIndex then
				table.remove(model.index, i)
				model.sorted = false
				model.updateCount = model.updateCount + 1
				for _, listener in pairs(model.updateListeners) do
					listener.func(listener.arg)
				end
				log:Debug("_RemovePendingRow: removed row with auction index %d", targetIndex)
				return
			end
		end
		log:Debug("_RemovePendingRow: auction index %d not found in model", targetIndex)
	end
end

-- [Titan Migration] 处理购买结果事件
local function _OnBuyEvent(self, event, arg1, arg2)
	if not self.pendingBuy then return end

	if event == "CHAT_MSG_SYSTEM" then
		local message = arg1
		if message == ERR_AUCTION_BID_PLACED then
			log:Debug("Purchase succeeded for [%s]", tostring(self.pendingBuy.name))
			vendor.Vendor:Print("Purchase succeeded: " .. tostring(self.pendingBuy.name))
			_RemovePendingRow(self)
			_UnregisterBuyEvents(self)
			-- 继续处理下一个拍卖品
			local auctions = self.auctions
			if #auctions > 0 then
				-- 还有更多拍卖品，不关闭对话框（等用户再次点击 OK）
				return
			else
				self.decisionMade = 1
				self:Hide()
				return
			end
		end
	elseif event == "UI_ERROR_MESSAGE" then
		local errorType, message
		if arg2 then
			errorType = arg1
			message = arg2
		else
			message = arg1
		end
		-- 检测购买失败的错误消息
		if message == ERR_ITEM_NOT_FOUND
			or message == ERR_NOT_ENOUGH_MONEY
			or message == ERR_AUCTION_BID_OWN
			or message == ERR_AUCTION_HIGHER_BID
			or message == ERR_ITEM_MAX_COUNT
			or (ERR_AUCTION_DATABASE_ERROR and message == ERR_AUCTION_DATABASE_ERROR)
			or errorType == 467 then
			log:Debug("Purchase failed for [%s]: %s", tostring(self.pendingBuy.name), tostring(message))
			vendor.Vendor:Error("Purchase failed: " .. tostring(self.pendingBuy.name) .. " - " .. tostring(message))
			_UnregisterBuyEvents(self)
			-- 购买失败，关闭对话框，行保留在搜索列表中
			self.decisionMade = 0
			self:Hide()
		end
	end
end

local function _OnOk(self)
	-- [Titan Migration] 如果有正在等待结果的购买，不处理新的点击
	if self.pendingBuy then
		log:Debug("_OnOk: purchase still pending, ignoring click")
		return
	end

	local auctions = self.auctions
	while (#auctions > 0) do
		local info = table.remove(auctions)
		if (info.index and info.index > 0) then
			-- 验证拍卖品数据是否仍然有效
			local name, _, count, _, _, _, _, minBid, _, buyout = GetAuctionItemInfo(self.ahType, info.index)
			if (name) then
				log:Debug("_OnOk: index=%d name=[%s] buyout=%s bid=%s ahType=[%s]",
					info.index, tostring(name), tostring(buyout), tostring(info.bid), tostring(self.ahType))
				vendor.Vendor:Print("Buying: " .. tostring(name) .. " index=" .. info.index ..
					" buyout=" .. tostring(buyout) .. " bid=" .. tostring(info.bid))
				-- [Titan Migration] 记录待购买信息，监听事件确认结果后再移除行
				self.pendingBuy = info
				self.eventFrame:RegisterEvent("CHAT_MSG_SYSTEM")
				self.eventFrame:RegisterEvent("UI_ERROR_MESSAGE")
				PlaceAuctionBid(self.ahType, info.index, info.bid)
			else
				vendor.Vendor:Error("Auction data expired at index " .. info.index .. " - try searching again")
			end
			break
		end
	end
	-- 如果没有待购买的（所有 index 都无效），关闭对话框
	if (#auctions == 0 and not self.pendingBuy) then
		self.decisionMade = 1
		self:Hide()
	end
end

local function _OnCancel(self)
	_UnregisterBuyEvents(self)
	self.decisionMade = 0
	self:Hide()
end

--[[
	Initilaizes the frame.
--]]
local function _InitFrame(self)
	local frame = CreateFrame("Frame", nil, UIParent, "VendorDialogTemplate")
	frame.obj = self
	self.frame = frame
	frame:SetWidth(FRAME_WIDTH)
	frame:SetHeight(FRAME_HEIGHT)
	frame:SetPoint("CENTER")
	frame:SetFrameStrata("DIALOG")
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:SetToplevel(true)
	frame:SetClampedToScreen(true)
	frame:SetScript("OnMouseDown", function(this) this:StartMoving() end)
	frame:SetScript("OnMouseUp", function(this) this:StopMovingOrSizing() end)

	-- intro text
	local text = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	text:SetPoint("TOPLEFT", 5, -10)
	text:SetText(L["Do you want to bid on the following auctions?"])

	-- auctions table
	local itemModel = vendor.ScannerItemModel:new(true)
	self.itemModel = itemModel
	itemModel.descriptors[vendor.ScannerItemModel.REASON].minWidth = 70
	itemModel.descriptors[vendor.ScannerItemModel.REASON].weight = 15
	local itemTableCfg = {
		rowHeight = 20,
		selected = {
			[1] = vendor.ScannerItemModel.TEXTURE,
			[2] = vendor.ScannerItemModel.NAME,
			[3] = vendor.ScannerItemModel.REASON,
			[4] = vendor.ScannerItemModel.BID,
			[5] = vendor.ScannerItemModel.BUYOUT
		},
	}

	local cmds = {
		[1] = {
			title = L["Ok"],
    		arg1 = self,
    		func = _OnOk,
    	},
    	[2] = {
    		title = L["Cancel"],
    		arg1 = self,
    		func = _OnCancel,
    	},
	}
	local cfg = {
		name = "AMBuyDialogAuctions",
		parent = frame,
		itemModel = itemModel,
		cmds = cmds,
		config = itemTableCfg,
		width = TABLE_WIDTH,
		height = TABLE_HEIGHT,
		xOff = TABLE_X_OFF,
		yOff = TABLE_Y_OFF,
		sortButtonBackground = true,
	}
	local itemTable = vendor.ItemTable:new(cfg)
	self.itemTable = itemTable

	-- [Titan Migration] 创建事件帧用于监听购买结果
	local eventFrame = CreateFrame("Frame")
	eventFrame.obj = self
	eventFrame:SetScript("OnEvent", function(ef, event, ...)
		_OnBuyEvent(ef.obj, event, ...)
	end)
	self.eventFrame = eventFrame
end

--[[
	Creates a new instance.
--]]
function vendor.BuyDialog:new()
	local instance = setmetatable({}, self.metatable)
	_InitFrame(instance)
	instance.frame:Hide()
	return instance
end

--[[
	Opens the dialog and shows the given auctions. Returns true, if the user bought them.
--]]
function vendor.BuyDialog.prototype:AskToBuy(ahType, auctions)
	log:Debug("AskToBuy enter")
	self.decisionMade = nil
	self.ahType = ahType
	self.auctions = auctions
	self.searchItemModel = nil
	local itemModel = self.itemModel
	itemModel:Clear()
	log:Debug("AskToBuy 1")
	for i=1,#auctions do
		local info = auctions[i]
		itemModel:AddItem(info.itemLink, info.itemLinkKey, info.name, info.texture, info.timeLeft, info.count,
			info.minBid, 0, info.buyout, info.bidAmount, "", info.reason, "", 0, info.quality)
	end
	log:Debug("AskToBuy 2")
	self.frame:Show()
	self.itemTable:Show()
	log:Debug("AskToBuy 3")
	_WaitForDecision(self)
	log:Debug("AskToBuy 4")
	return (self.decisionMade and (1 == self.decisionMade))
end

--[[
	Hides the dialog frame.
--]]
function vendor.BuyDialog.prototype:Hide()
	_UnregisterBuyEvents(self)
	self.frame:Hide();
end

--[[
	Returns whether the dialog is visible
--]]
function vendor.BuyDialog.prototype:IsVisible()
	return self.frame:IsVisible()
end

--[[
	Shows the dialog for direct buying (non-coroutine). The user clicks Ok to
	confirm and PlaceAuctionBid is called from the dialog button's OnClick
	(parented to UIParent), bypassing AuctionFrame's protected frame restriction.
--]]
-- [Titan Migration] PlaceAuctionBid 是受保护函数，不能从 AuctionFrame 内的按钮调用；
-- 通过此对话框的按钮（parent 为 UIParent）触发，硬件事件可正常传播。
-- searchItemModel 参数用于在购买成功后从搜索列表移除对应行。
function vendor.BuyDialog.prototype:ShowForDirectBuy(ahType, auctions, possibleGap, searchItemModel)
	self.decisionMade = nil
	self.pendingBuy = nil
	self.ahType = ahType
	self.auctions = auctions
	self.possibleGap = possibleGap
	self.searchItemModel = searchItemModel
	local itemModel = self.itemModel
	itemModel:Clear()
	for i = 1, #auctions do
		local info = auctions[i]
		local _, _, quality, _, _, _, _, _, _, texture = GetItemInfo(info.itemLink)
		itemModel:AddItem(info.itemLink, nil, info.name, texture, nil, info.count,
			info.minBid, 0, info.buyout, info.bidAmount, "", info.reason or "", "", 0, quality or 1)
	end
	self.frame:Show()
	self.itemTable:Show()
end
