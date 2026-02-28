# WoW API 变更追踪

> 记录泰坦重铸迁移过程中发现的所有 API 差异和变更。

## 泰坦重铸 vs 经典怀旧服的关键差异

| 类别 | 差异描述 | 影响范围 | 解决方案 |
|------|----------|----------|----------|
| Interface 版本号 | 20501 → 38000 | `AuctionMaster_Titan.toc` | 已更新 |
| TOC 文件名 | 需匹配插件文件夹名 | `AuctionMaster.toc` → `AuctionMaster_Titan.toc` | 已重命名 |
| XML Backdrop | `<Backdrop>` XML 元素可直接使用 | `<Backdrop>` XML 元素已移除，需用 `BackdropTemplate` + Lua `SetBackdrop()` | 所有含 `<Backdrop>` 的 XML 模板 | 继承 `BackdropTemplate`，在 `<OnLoad>` 中调用 `SetBackdrop()` |
| Lua SetBackdrop | 任意 Frame 可调用 `SetBackdrop()` | 仅继承 `BackdropTemplate` 的 Frame 可调用 | 所有 Lua 中调用 `SetBackdrop` 的代码 | `CreateFrame` 时添加 `"BackdropTemplate"` 参数，或用 `Mixin(frame, BackdropTemplateMixin)` |

## 受保护函数变更

| API / 函数 | 旧版行为 | 新版行为 | 影响范围 | 备注 |
|------------|----------|----------|----------|------|
| `PlaceAuctionBid()` | 可从插件代码自由调用，循环内可多次调用 | 绑定硬件事件（鼠标操作码），每次按钮点击只能成功调用一次，调用后事件标记即被消耗，后续调用触发 `ADDON_ACTION_BLOCKED` | 所有购买/竞标路径 | 需要购买多件时，每件必须对应一次独立的按钮点击 |
| `PlaceAuctionBid()` 前置条件 | 可直接传入 index 调用，无需先选中 | 必须先调用 `SetSelectedAuctionItem(type, index)` 选中拍卖品，否则服务端返回 error 467 | 所有购买/竞标路径 | 在每次 `PlaceAuctionBid` 前添加 `SetSelectedAuctionItem` |

## WoW API 变更明细

| API / 函数 | 旧版行为 | 新版行为 | 影响的文件 | 修复方式 |
|------------|----------|----------|-----------|----------|
| `SimpleHTML:SetFontObject(font)` | 可省略 textType 设置默认字体 | 必须提供 textType 参数：`SetFontObject(textType, font)` | `src/main/Gui/AceGUIWidget-ScrollableSimpleHTML.lua` | 改为 `SetFontObject("p", font)` |
| `<Backdrop>` XML 元素 | 可在 XML 中直接定义 Backdrop | 已移除，需用 Lua API | `src/xml/VendorDialogTemplate.xml`, `src/xml/ItemSettingsTemplates.xml`, `libs/NoTaintUIDropDownMenu/UIDropDownMenuTemplates.xml` | 继承 `BackdropTemplate` + `OnLoad` 中 `SetBackdrop({...})` |
| `Frame:SetBackdrop()` | 所有 Frame 默认可用 | 仅 `BackdropTemplate` 继承的 Frame 可用 | `src/main/Gui/AceGUIWidget-TreeMenu.lua` | `CreateFrame` 时传入 `"BackdropTemplate"` |
| `GetContainerItemInfo(bag, slot)` | 返回多个值：`texture, itemCount, locked, quality, readable, lootable, itemLink, isFiltered, noValue, itemID` | 移至 `C_Container.GetContainerItemInfo()`，返回单个 table：`{iconFileID, stackCount, isLocked, quality, isReadable, hasLoot, hyperlink, isFiltered, hasNoValue, itemID, ...}` | `src/main/Seller/InventoryHandle.lua`, `src/main/Seller/InventoryItemModel.lua`, `src/main/Seller/Seller.lua`, `src/main/TooltipHook/TooltipHook.lua` | 用兼容包装函数将 table 返回值展开为多返回值 |
| `PickupContainerItem(bag, slot)` | 全局函数可直接调用 | 移至 `C_Container.PickupContainerItem()` | `src/main/Seller/Seller.lua`, `src/main/Seller/InventoryHandle.lua` | `local PickupContainerItem = PickupContainerItem or C_Container.PickupContainerItem` |
| `SplitContainerItem(bag, slot, count)` | 全局函数可直接调用 | 移至 `C_Container.SplitContainerItem()` | `src/main/Seller/InventoryHandle.lua` | `local SplitContainerItem = SplitContainerItem or C_Container.SplitContainerItem` |
| `PostAuction(minBid, buyoutPrice, runTime, stackSize, stackCount)` | 接受 5 个参数，含 stackSize 和 stackCount | 改为 `PostAuction(minBid, buyoutPrice, runTime, warningAcknowledged)`，移除堆叠参数，新增 warningAcknowledged 布尔值 | `src/main/Seller/Seller.lua` | 移除 stackSize/stackCount 参数，传入 `true` 跳过警告；Hook 函数中通过 `GetAuctionSellItemInfo()` 获取 count 代替 stackSize |

## 拍卖行扫描策略变更

| 变更项 | 旧版行为 | 新版行为 | 影响的文件 | 原因 |
|--------|----------|----------|-----------|------|
| 分页扫描页数 | 翻阅所有页面直到读完 | 默认只读第 1 页，可通过 `queryInfo.maxPages` 配置 | `src/main/Scanner/ScanTask.lua` | 泰坦重铸拍卖行限流，减少 `QueryAuctionItems` 调用次数 |
| 查询前排序 | 不主动排序，沿用用户上次排序状态 | 查询前先调用 `SortAuctionClearSort("list")` 清空排序栈，再调用 `SortAuctionItems("list", "buyout")` 按一口价升序排列 | `src/main/Scanner/ScanTask.lua` | `SortAuctionItems` 是切换式 API，重复调用会在升序/降序间翻转；必须先清空排序栈确保始终升序 |
| 查询后节流等待 | 查询返回后、读取结果前再次调用 `_BlockForCanSendAuctionQuery` | 移除该等待，仅保留循环顶部的节流检查 | `src/main/Scanner/ScanTask.lua` | 结果已返回后无需等待再次查询许可，多页扫描由循环顶部覆盖；原逻辑导致单页搜索超时 12 秒 |
