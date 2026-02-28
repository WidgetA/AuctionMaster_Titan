# 已知问题与解决方案

> 开发中遇到的问题和最终解决方案，按时间倒序排列。

---

### [2026-02-28] PlaceAuctionBid 服务端 error 467（未解决）
- **现象**：使用插件一口价/竞标时，服务端返回 error 467，购买失败；触发后拍卖行数秒内不可用。不使用插件时原生 UI 一口价几乎 100% 成功
- **状态**：❌ 未解决，以下方案均已尝试失败，详见 CLAUDE.md「无效尝试记录」
- **涉及文件**：`src/main/Scanner/BuyDialog.lua`（`_OnOk` 和 `ShowForDirectBuy`）

---

### [2026-02-28] 搜索结果排序方向交替翻转，偶尔显示非最低价物品
- **现象**：在搜索页搜索物品时，偶尔（大约每隔一次搜索）第一页显示的不是最便宜的物品，而是明显不属于第一页的结果
- **原因**：`_PagedScan` 中每次搜索前调用 `SortAuctionItems("list", "buyout")`，但该 API 是**切换式**的——每次调用在升序/降序之间翻转。第一次搜索设为升序，第二次就变成降序，第三次又升序，以此类推
- **解决**：在 `SortAuctionItems` 之前调用 `SortAuctionClearSort("list")` 清空排序栈，确保每次都从干净状态开始，`SortAuctionItems` 始终设为升序
- **涉及文件**：`src/main/Scanner/ScanTask.lua`

---

### [2026-02-28] PlaceAuctionBid ADDON_ACTION_BLOCKED
- **现象**：选中多个拍卖品后点击「竞标」或「一口价」按钮，报错 `ADDON_ACTION_BLOCKED: 插件 'AuctionMaster_Titan' 尝试调用保护功能 'PlaceAuctionBid()'`；选中单个拍卖品则正常
- **原因**：泰坦重铸中 `PlaceAuctionBid()` 绑定硬件事件（鼠标操作码），每次点击只能成功调用一次，调用后事件标记即被消耗，后续调用全部被拦截
- **解决**：跳过原有的 BuyScan 二次扫描流程，改为弹出 BuyDialog 确认对话框，每次点击 Ok 只调用一次 `PlaceAuctionBid` 购买一件物品，剩余物品保持对话框打开等待下一次点击
- **涉及文件**：`src/main/Search/SearchTab.lua`（`_Bid` 和 `_Buyout`），`src/main/Scanner/BuyDialog.lua`（`_OnOk` 和 `ShowForDirectBuy`）

---

### [2026-02-28] 搜索时 12 秒超时弹窗 "AuctionHouse not ready"
- **现象**：在搜索页点击搜索后，等待 12 秒弹出 "AuctionHouse not ready, even after waiting for 12 seconds" 错误对话框
- **原因**：`_PagedScan` 中 `QueryAuctionItems` 返回结果后、读取数据前，多调用了一次 `_BlockForCanSendAuctionQuery`。查询后服务器节流导致 `CanSendAuctionQuery()` 长时间返回 `false`，但此时结果已经拿到，不需要等待再次查询许可
- **解决**：移除 `_BlockForAuctionListUpdate` 之后多余的 `_BlockForCanSendAuctionQuery` 调用，循环顶部已有一个覆盖多页扫描场景
- **涉及文件**：`src/main/Scanner/ScanTask.lua`

---

### [2026-02-28] 自定义纹理路径修复 + getglobal 迁移
- **现象**：所有自定义纹理（高亮、背景、按钮图标等）均无法加载，右侧面板全黑
- **原因**：插件文件夹从 `AuctionMaster` 重命名为 `AuctionMaster_Titan`，但所有硬编码的纹理路径仍引用 `Interface\\Addons\\AuctionMaster\\...`，导致 WoW 找不到 `.tga` 文件，`SetTexture()` 静默失败
- **解决**：
  - 全局替换纹理路径 `AuctionMaster` → `AuctionMaster_Titan`（8 个文件，约 30 处）
  - 全局替换 `getglobal(...)` → `_G[...]`（9 个文件，15 处）
  - `_UpdateArrow` 添加 `if not arrow then return end` nil 保护
- **涉及文件**：`src/main/AuctionHouse/ItemTable.lua`, `src/main/AuctionHouse/AuctionHouse.lua`, `src/main/Seller/Seller.lua`, `src/main/Search/SearchTab.lua`, `src/main/Search/SearchList.lua`, `src/main/OwnAuctions/OwnAuctions.lua`, `src/main/Items/ItemSettings.lua`, `src/main/Scanner/ScanSetItemModel.lua`, `src/main/Gui/PopupMenu.lua`, `src/main/Gui/AceGUIWidget-ScrollableSimpleHTML.lua`, `src/main/Core/Debug.lua`, `src/main/Seller/InventoryItemModel.lua`, `src/main/Sniper/SnipeCreateDialog.lua`, `src/main/Scanner/Scanner.lua`
- **教训**：重命名插件文件夹后，必须同步更新所有 `Interface\\Addons\\<folder>\\` 硬编码路径

---

### [2026-02-28] GetContainerItemInfo 返回值从多值变为 table
- **现象**：`InventoryHandle.lua:60: attempt to perform arithmetic on field 'count' (a nil value)`
- **原因**：`C_Container.GetContainerItemInfo()` 在泰坦重铸中返回单个 table（含 `stackCount`, `isLocked` 等字段），而非旧版的多个返回值（`texture, itemCount, locked, ...`）。原有代码 `local _, count = GetContainerItemInfo(bag, slot)` 中 `count` 为 nil
- **解决**：将简单别名替换为兼容包装函数，将 table 字段展开为多返回值，保持所有调用点不变
- **涉及文件**：`src/main/Seller/InventoryHandle.lua`, `src/main/Seller/InventoryItemModel.lua`, `src/main/Seller/Seller.lua`, `src/main/TooltipHook/TooltipHook.lua`
