# AuctionMaster Titan Reforged

AuctionMaster 的泰坦重铸（Titan Reforged）迁移版本。一款功能齐全的魔兽世界拍卖行辅助插件，提供拍卖行统计、智能定价、一键上架、狙击捡漏和高级搜索等功能。

## 安装

1. 下载本仓库或从 Release 页面获取最新版本
2. 将 `AuctionMaster_Titan` 文件夹放入 WoW 插件目录：
   ```
   <WoW安装目录>/Interface/AddOns/AuctionMaster_Titan/
   ```
3. 重启游戏或在角色选择界面刷新插件列表

> **注意**：文件夹名称必须为 `AuctionMaster_Titan`，与 `.toc` 文件名一致。

## 功能特性

- **拍卖行扫描** — 支持分页扫描和 GetAll 快速全量扫描，收集市场价格数据
- **智能定价** — 基于市场数据自动推荐上架价格，支持多种定价策略（固定价/市场价/当前最低价）
- **一键上架** — 从背包选择物品后自动填充价格，支持堆叠拆分和批量上架
- **我的拍卖** — 管理已上架的拍卖，支持批量取消
- **狙击系统** — 实时检测低价物品，支持四种狙击策略：
  - 收藏搜索匹配
  - 低于商店售价
  - 低于分解材料价值
  - 低于市场均价
- **高级搜索** — 多条件搜索过滤，支持搜索收藏和重命名
- **价格统计** — 45 天历史价格追踪，鼠标提示注入价格信息
- **物品设置** — 对单个物品自定义堆叠数量、拍卖时长和定价模型

## 版本信息

| 项目 | 值 |
|------|-----|
| 目标客户端 | 泰坦重铸 (Titan Reforged) |
| Interface 版本 | 38000 |
| 插件版本 | 9.0.0 |
| 框架 | Ace3 (Release r1390) |
| 原始版本 | AuctionMaster for Classic TBC (Interface 20501) |

## 斜杠命令

- `/vendor` 或 `/vd` — 打开设置面板
- `/vendor help` — 显示帮助信息
- `/vendor scan` — 开始拍卖行扫描（需要在拍卖行 NPC 前）

## 项目结构

```
AuctionMaster_Titan.toc      <- 插件入口
├── libs/                    <- 第三方库 (Ace3, LibBabble, NoTaintUIDropDownMenu)
├── src/
│   ├── xml/                 <- UI 模板 (XML Frame Templates)
│   ├── locale/              <- 多语言支持 (enUS, deDE, zhCN, zhTW, ruRU 等)
│   ├── main/                <- 核心业务模块 (14 个子模块)
│   ├── api/                 <- 对外公开 API
│   └── test/                <- 测试
└── doc/                     <- 项目文档
```

详细架构说明见 [doc/ARCHITECTURE.md](doc/ARCHITECTURE.md)。

## 迁移说明

本版本从 Classic TBC 迁移而来，主要变更包括：

- Interface 版本号升级至 38000
- Ace3 库升级至 r1390
- XML `<Backdrop>` 元素迁移至 `BackdropTemplate` + Lua API
- `getglobal()` 全部替换为 `_G[]`
- `GetContainerItemInfo` 适配新版返回值格式（table）
- `SimpleHTML:SetFontObject` 适配新版参数要求
- 所有硬编码纹理路径更新为新文件夹名

详细 API 变更记录见 [doc/API_CHANGES.md](doc/API_CHANGES.md)。

## 对外 API

供其他插件调用：

```lua
-- 获取物品历史统计信息
AucMasGetAuctionInfo(itemLink, neutralAh)

-- 获取当前扫描统计信息
AucMasGetCurrentAuctionInfo(itemLink, neutralAh, adjustPrices)

-- 注册统计更新回调
AucMasRegisterStatisticCallback(func, arg)

-- 获取当前/历史一口价
GetAuctionBuyout(itemLink)
```

## 致谢

- 原作者 Udorn 开发了 AuctionMaster 插件
- [Ace3](https://www.wowace.com/projects/ace3) 框架
- [LibBabble-Inventory-3.0](https://www.wowace.com/projects/libbabble-inventory-3-0) 物品分类本地化

## 许可

本项目基于原 AuctionMaster 插件修改，遵循其原始许可协议。
