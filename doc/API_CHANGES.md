# WoW API 变更追踪

> 记录泰坦重铸迁移过程中发现的所有 API 差异和变更。

## 泰坦重铸 vs 经典怀旧服的关键差异

| 类别 | 差异描述 | 影响范围 | 解决方案 |
|------|----------|----------|----------|
| Interface 版本号 | 20501 → 38000 | `AuctionMaster_Titan.toc` | 已更新 |
| TOC 文件名 | 需匹配插件文件夹名 | `AuctionMaster.toc` → `AuctionMaster_Titan.toc` | 已重命名 |
| XML Backdrop | `<Backdrop>` XML 元素可直接使用 | `<Backdrop>` XML 元素已移除，需用 `BackdropTemplate` + Lua `SetBackdrop()` | 所有含 `<Backdrop>` 的 XML 模板 | 继承 `BackdropTemplate`，在 `<OnLoad>` 中调用 `SetBackdrop()` |
| Lua SetBackdrop | 任意 Frame 可调用 `SetBackdrop()` | 仅继承 `BackdropTemplate` 的 Frame 可调用 | 所有 Lua 中调用 `SetBackdrop` 的代码 | `CreateFrame` 时添加 `"BackdropTemplate"` 参数，或用 `Mixin(frame, BackdropTemplateMixin)` |

## WoW API 变更明细

| API / 函数 | 旧版行为 | 新版行为 | 影响的文件 | 修复方式 |
|------------|----------|----------|-----------|----------|
| `SimpleHTML:SetFontObject(font)` | 可省略 textType 设置默认字体 | 必须提供 textType 参数：`SetFontObject(textType, font)` | `src/main/Gui/AceGUIWidget-ScrollableSimpleHTML.lua` | 改为 `SetFontObject("p", font)` |
| `<Backdrop>` XML 元素 | 可在 XML 中直接定义 Backdrop | 已移除，需用 Lua API | `src/xml/VendorDialogTemplate.xml`, `src/xml/ItemSettingsTemplates.xml`, `libs/NoTaintUIDropDownMenu/UIDropDownMenuTemplates.xml` | 继承 `BackdropTemplate` + `OnLoad` 中 `SetBackdrop({...})` |
| `Frame:SetBackdrop()` | 所有 Frame 默认可用 | 仅 `BackdropTemplate` 继承的 Frame 可用 | `src/main/Gui/AceGUIWidget-TreeMenu.lua` | `CreateFrame` 时传入 `"BackdropTemplate"` |
| `GetContainerItemInfo(bag, slot)` | 返回多个值：`texture, itemCount, locked, quality, readable, lootable, itemLink, isFiltered, noValue, itemID` | 移至 `C_Container.GetContainerItemInfo()`，返回单个 table：`{iconFileID, stackCount, isLocked, quality, isReadable, hasLoot, hyperlink, isFiltered, hasNoValue, itemID, ...}` | `src/main/Seller/InventoryHandle.lua`, `src/main/Seller/InventoryItemModel.lua`, `src/main/Seller/Seller.lua`, `src/main/TooltipHook/TooltipHook.lua` | 用兼容包装函数将 table 返回值展开为多返回值 |
