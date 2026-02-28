# 迁移进度记录

## 已完成

- [x] 项目初始化，建立架构文档
- [x] 确认泰坦重铸版本的 Interface 版本号（38000）
- [x] 更新 TOC 文件（重命名 + Interface 版本号 + Title）
- [x] Ace3 库升级至 Release r1390（2026-02-03）
- [x] 修复 SimpleHTML:SetFontObject API 变更（需传 textType 参数）
- [x] 迁移所有 XML `<Backdrop>` 到 `BackdropTemplate` + Lua（VendorDialogTemplate, ItemSettingsTemplates, NoTaintUIDropDownMenu）
- [x] 修复 AceGUIWidget-TreeMenu.lua 缺少 BackdropTemplate 的问题
- [x] 修复 `C_Container.GetContainerItemInfo()` 返回值变更（多值→table）
- [x] 修复所有自定义纹理路径 `AuctionMaster` → `AuctionMaster_Titan`（8 文件，约 30 处）
- [x] 全局替换 `getglobal()` → `_G[]`（9 文件，15 处）
- [x] `_UpdateArrow` 添加 Arrow nil 保护
