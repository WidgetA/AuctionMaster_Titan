# 已知问题与解决方案

> 开发中遇到的问题和最终解决方案，按时间倒序排列。

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
