# AuctionMaster 项目架构文档

> WoW 经典怀旧服拍卖行辅助插件，基于 Ace3 框架，提供拍卖行统计、定价、上架、狙击、搜索等功能。

## 一、项目总览

```
AuctionMaster.toc          ← 插件入口，定义加载顺序
├── libs/                  ← 第三方库
│   ├── Ace3/              ← Ace3 全家桶（AceAddon, AceDB, AceGUI, AceEvent 等）
│   ├── LibBabble-Inventory-3.0/  ← 物品分类本地化库
│   └── NoTaintUIDropDownMenu/    ← 无污染下拉菜单（已注释禁用）
├── src/
│   ├── xml/               ← UI 模板定义（XML Frame Templates）
│   ├── locale/            ← 多语言翻译（enUS, deDE, zhCN, zhTW, ruRU 等）
│   ├── main/              ← 核心业务模块（14 个子模块）
│   ├── api/               ← 对外公开 API
│   └── test/              ← 测试文件
```

**加载顺序**（TOC 定义）：
1. `libs/Import.xml` → 第三方库
2. `src/xml/Import.xml` → UI 模板
3. `src/locale/Import.xml` → 本地化
4. `src/main/Import.xml` → 业务模块
5. `src/api/Import.xml` → 公开 API
6. `src/test/Import.xml` → 测试

**全局命名空间**：所有模块挂载在 `vendor` 全局表下。
**SavedVariables**：`VendorDb`（AceDB 主数据库）、`AuctionMasterMiscDb`（调试等杂项）

---

## 二、模块总览（14 个子模块）

| # | 模块 | 路径 | 核心职责 |
|---|------|------|----------|
| 1 | **Core** | `src/main/Core/` | 基础设施：全局命名空间、调试、数据库、工具函数 |
| 2 | **Gui** | `src/main/Gui/` | 自定义 AceGUI 控件和 UI 工具函数 |
| 3 | **TaskQueue** | `src/main/TaskQueue/` | 协程任务队列，异步任务调度 |
| 4 | **Help** | `src/main/Help/` | 帮助文档树形浏览器 |
| 5 | **AuctionHouse** | `src/main/AuctionHouse/` | 拍卖行 UI 集成、Tab 管理、事件总线 |
| 6 | **TooltipHook** | `src/main/TooltipHook/` | 鼠标提示信息注入（价格/统计） |
| 7 | **OwnAuctions** | `src/main/OwnAuctions/` | 玩家自身拍卖管理（查看/取消） |
| 8 | **Seller** | `src/main/Seller/` | 卖家 Tab：定价、上架、背包管理 |
| 9 | **Items** | `src/main/Items/` | 物品数据库：物品信息存储与查询 |
| 10 | **Scanner** | `src/main/Scanner/` | 拍卖行扫描引擎（分页/全量/搜索） |
| 11 | **Sniper** | `src/main/Sniper/` | 狙击系统：低价检测与自动提醒 |
| 12 | **Statistic** | `src/main/Statistic/` | 统计系统：价格历史、趋势分析 |
| 13 | **Search** | `src/main/Search/` | 搜索 Tab：高级搜索与收藏 |
| 14 | **Disenchant** | `src/main/Disenchant/` | 分解数据库：物品→材料映射与利润计算 |

---

## 三、各模块详细说明

### 1. Core — 基础设施层

**文件列表**：Core.lua, Debug.lua, AceDb20.lua, Math.lua, Format.lua, Deque.lua, LruCache.lua, Vendor.lua, Config.lua, Tables.lua, Strings.lua

| 文件 | 职责 |
|------|------|
| `Core.lua` | 定义 `vendor` 全局表，通用工具函数（类型检查、字符串、Frame） |
| `Debug.lua` | `vendor.Debug` 调试日志系统，支持命名实例和颜色输出 |
| `AceDb20.lua` | AceDB-2.0 兼容层，用于旧数据迁移 |
| `Math.lua` | 数学工具：均值、中位数、标准差、离群值清理 |
| `Format.lua` | 格式化工具：金币显示、品质颜色、价格对比 |
| `Deque.lua` | 双端队列数据结构 |
| `LruCache.lua` | LRU 缓存（基于 Deque），用于高频查询优化 |
| `Vendor.lua` | **插件主入口** — AceAddon 实例 `vendor.Vendor`，生命周期管理 |
| `Config.lua` | 配置 UI 模块，管理全局设置面板 |
| `Tables.lua` | 表工具：二分查找、表复制 |
| `Strings.lua` | 字符串工具：二进制序列化、字符串分割 |

### 2. Gui — GUI 控件层

**文件列表**：AceGUIWidget-ScrollableSimpleHTML.lua, AceGUIWidget-TreeMenu.lua, AceGUIWidget-EditDropDown.lua, PopupMenu.lua, GuiTools.lua

| 文件 | 职责 |
|------|------|
| `ScrollableSimpleHTML` | 可滚动 HTML 控件（用于帮助文档） |
| `TreeMenu` | 树形菜单控件（用于帮助/设置导航） |
| `EditDropDown` | 可编辑下拉框（支持数值验证和多选） |
| `PopupMenu.lua` | 右键弹出菜单系统 |
| `GuiTools.lua` | UI 工厂函数：按钮、复选框、纹理、下拉框创建 |

### 3. TaskQueue — 异步任务系统

**文件列表**：SimpleTask.lua, TaskQueue.lua

- `SimpleTask` — 简单的函数包装任务
- `TaskQueue` — 基于协程的任务调度器，每帧执行一步，支持取消

**设计模式**：所有任务实现统一接口 `Run()`, `Cancel()`, `IsCancelled()`, `Failed()`

### 4. AuctionHouse — 拍卖行集成

**文件列表**：ItemTableCell.lua, TextureCell.lua, TextCell.lua, ItemTable.lua, CancelTask.lua, AuctionHouse.lua

| 文件 | 职责 |
|------|------|
| `ItemTableCell` | 表格单元格基类 |
| `TextureCell` | 图标单元格（支持 Tooltip 和点击回调） |
| `TextCell` | 文字单元格 |
| `ItemTable` | **通用数据表格控件** — 排序、多选、滚动、列配置菜单 |
| `CancelTask` | 拍卖取消任务（限速，防止服务器报错） |
| `AuctionHouse` | **拍卖行核心** — Tab 管理、Logo 动画、事件分发、物品分类字典 |

**关键事件**：`AUCTION_HOUSE_SHOW`, `AUCTION_HOUSE_CLOSED`, `CHAT_MSG_SYSTEM`

### 5. Seller — 卖家系统

**文件列表**：InventoryHandle.lua, AutomaticPriceModel.lua, BuyoutModifier.lua, SellingPrice.lua, SellInfo.lua, Seller.lua, InventoryItemModel.lua, InventorySeller.lua

| 文件 | 职责 |
|------|------|
| `InventoryHandle` | 背包操作：取物品、拆分堆叠、合并堆叠 |
| `AutomaticPriceModel` | 智能定价：根据市场情况自动选择定价策略 |
| `BuyoutModifier` | 价格修改器：按金额/百分比加减一口价 |
| `SellingPrice` | 价格数据封装（最低出价、一口价、押金） |
| `SellInfo` | 售卖信息 UI 显示区域 |
| `Seller` | **主卖家模块** — 卖家 Tab、定价模型选择、上架拍卖 |
| `InventoryItemModel` | 背包物品数据模型（与 ItemTable 配合） |
| `InventorySeller` | 背包物品列表 UI 封装 |

**定价模型**：支持多种模型切换（自动/手动/参考市场价）

### 6. Scanner — 扫描引擎

**文件列表**：ScanResults.lua, ScanSet.lua, ScanSetItemModel.lua, ScanTask.lua, ScanDialog.lua, BuyDialog.lua, BuyScanModule.lua, ScannerItemModel.lua, GatherScanModule.lua, SniperScanModule.lua, SearchScanModule.lua, GetAllPlaceAuctionTask.lua, Scanner.lua

**分层架构**：
```
Scanner.lua（主调度器）
├── ScanTask（扫描任务）
│   ├── GatherScanModule   → 收集统计数据
│   ├── SniperScanModule   → 检测狙击机会
│   ├── SearchScanModule   → 搜索过滤
│   └── BuyScanModule      → 购买匹配
├── ScanResults（数据序列化）
├── ScanSet（扫描结果集合）
├── ScanDialog / BuyDialog（用户交互）
└── GetAllPlaceAuctionTask（批量出价任务）
```

**插件式设计**：`ScanTask` 接受多个 `ScanModule`，每个 Module 实现统一接口：
- `StartScan()`, `StopScan()`, `StartPage()`, `StopPage()`, `NotifyAuction()`

### 7. Statistic — 统计系统

**文件列表**：CanUseEval.lua, StatisticDb.lua, ApproxAverage.lua, ArchiveTask.lua, Gatherer.lua, Statistic.lua

| 文件 | 职责 |
|------|------|
| `CanUseEval` | 判断物品是否可被当前角色使用（带缓存） |
| `StatisticDb` | 统计数据库：45 天历史数据压缩存储 |
| `ApproxAverage` | 近似移动平均算法 |
| `ArchiveTask` | 异步归档扫描数据的任务 |
| `Gatherer` | **数据采集核心** — 管理快照、收集拍卖信息、提供查询接口 |
| `Statistic` | **统计展示** — Tooltip 注入价格统计、对外查询接口 |

**数据存储**：`factionrealm.snapshot`（阵营+服务器）、`realm.snapshot`（中立拍卖行）

### 8. Sniper — 狙击系统

**文件列表**：SniperConfig.lua, BookmarkSniper.lua, SellPriceSniper.lua, DisenchantSniper.lua, MarketPriceSniper.lua, SnipeCreateDialog.lua, Sniper.lua

**狙击策略（可并行运行）**：

| 策略 | 逻辑 |
|------|------|
| `BookmarkSniper` | 匹配收藏搜索中的低价物品 |
| `SellPriceSniper` | 拍卖价低于商店售价 → 买来卖店赚差价 |
| `DisenchantSniper` | 拍卖价低于分解材料价值 |
| `MarketPriceSniper` | 拍卖价低于市场均价的一定比例 |

### 9. 其他模块

| 模块 | 核心职责 |
|------|----------|
| **OwnAuctions** | 显示/管理玩家已上架的拍卖，支持批量取消 |
| **Items** | 物品数据库：存储所有已知物品的信息、单独设置（堆叠/时长/定价） |
| **Search** | 搜索 Tab：高级搜索条件、搜索收藏列表 |
| **Disenchant** | 分解数据库：物品类型+品质+等级→分解产物映射表 |
| **TooltipHook** | Hook 所有 Tooltip，注入拍卖价格/统计/狙击信息 |
| **Help** | 帮助文档浏览器（树形导航 + HTML 内容） |

### 10. API — 公开接口

**文件**：`src/api/Statistic.lua`

供其他插件调用的全局函数：
- `AucMasGetAuctionInfo(itemLink, neutralAh)` — 获取历史统计
- `AucMasGetCurrentAuctionInfo(itemLink, neutralAh, adjustPrices)` — 获取当前扫描统计
- `AucMasRegisterStatisticCallback(func, arg)` — 注册统计更新回调
- `GetAuctionBuyout(itemLink)` — 获取当前/历史一口价

---

## 四、模块依赖关系图

```
                           ┌─────────────────────────┐
                           │      libs (Ace3)         │
                           │  LibStub, AceAddon,      │
                           │  AceDB, AceGUI, AceEvent │
                           │  AceHook, AceTimer ...   │
                           └────────────┬─────────────┘
                                        │
                           ┌────────────▼─────────────┐
                           │      Core 基础设施层       │
                           │  vendor 命名空间           │
                           │  Debug, Math, Format      │
                           │  Deque, LruCache, Tables  │
                           │  Strings, AceDb20         │
                           │  Vendor (主入口), Config   │
                           └────────────┬─────────────┘
                                        │
              ┌─────────────────────────┼─────────────────────────┐
              │                         │                         │
   ┌──────────▼──────────┐   ┌─────────▼──────────┐   ┌─────────▼──────────┐
   │     Gui 控件层       │   │   TaskQueue 任务队列 │   │   Locale 本地化     │
   │  TreeMenu, PopupMenu │   │  SimpleTask          │   │   多语言翻译        │
   │  EditDropDown         │   │  TaskQueue (协程)    │   └────────────────────┘
   │  GuiTools             │   └─────────┬──────────┘
   └──────────┬──────────┘              │
              │                         │
   ┌──────────▼──────────────────────────▼─────────────────────────┐
   │                    AuctionHouse 拍卖行核心                     │
   │  Tab 管理 | 事件分发 | ItemTable 表格控件 | CancelTask         │
   └───┬──────────┬──────────┬──────────┬──────────┬───────────────┘
       │          │          │          │          │
   ┌───▼───┐ ┌───▼───┐ ┌───▼───┐ ┌───▼───┐ ┌───▼────────┐
   │Seller │ │OwnAuc │ │Search │ │Scanner│ │TooltipHook │
   │卖家Tab│ │我的拍卖│ │搜索Tab│ │扫描引擎│ │提示信息注入 │
   └───┬───┘ └───┬───┘ └───┬───┘ └───┬───┘ └───┬────────┘
       │         │         │         │          │
       │         │         │    ┌────┴────┐     │
       │         │         │    │ScanModule│     │
       │         │         │    │(插件架构)│     │
       │         │         │    └────┬────┘     │
       │         │         │         │          │
   ┌───▼─────────▼─────────▼─────────▼──────────▼───┐
   │              Items 物品数据库                     │
   │         Statistic / Gatherer 统计系统             │
   │              Disenchant 分解数据库                │
   └─────────────────────┬───────────────────────────┘
                         │
              ┌──────────▼──────────┐
              │    Sniper 狙击系统    │
              │  Bookmark / SellPrice│
              │  Disenchant / Market │
              └──────────┬──────────┘
                         │
              ┌──────────▼──────────┐
              │   API 公开接口       │
              │  AucMasGet*()        │
              └─────────────────────┘
```

---

## 五、关键设计模式

### 1. 原型继承（Prototype Pattern）
几乎所有类都使用 Lua 元表模拟 OOP：
```lua
vendor.SomeClass = {}
vendor.SomeClass.prototype = {}
vendor.SomeClass.prototype.__index = vendor.SomeClass.prototype
function vendor.SomeClass:new()
    local o = setmetatable({}, vendor.SomeClass.prototype)
    return o
end
```

### 2. AceAddon 模块系统
- 主插件：`vendor.Vendor = LibStub("AceAddon-3.0"):NewAddon(...)`
- 子模块：`vendor.XXX = vendor.Vendor:NewModule("XXX", ...)`
- 生命周期：`OnInitialize()` → `OnEnable()`

### 3. 协程驱动的异步任务
`TaskQueue` 使用 Lua 协程实现非阻塞操作：
- 扫描拍卖行（逐页翻页）
- 批量取消拍卖
- 数据归档
- 购买确认流程

### 4. 插件式扫描架构
`ScanTask` 接受多个可插拔的 `ScanModule`：
- `GatherScanModule` — 收集统计
- `SniperScanModule` — 检测低价
- `SearchScanModule` — 搜索过滤
- `BuyScanModule` — 购买匹配

### 5. ItemModel / ItemTable MVC 模式
- **Model**：`InventoryItemModel`, `OwnAuctionsItemModel`, `ScanSetItemModel`, `ScannerItemModel`
- **View**：`ItemTable`（通用表格控件）
- **Controller**：各 Tab 模块（Seller, OwnAuctions, Search）

---

## 六、数据流

```
玩家打开拍卖行
    │
    ▼
AuctionHouse.AUCTION_HOUSE_SHOW()
    │
    ├──→ Seller.InitTab() ─── 初始化卖家界面
    ├──→ OwnAuctions ─────── 加载玩家拍卖
    └──→ SearchTab ────────── 初始化搜索界面

扫描流程:
    Scanner.Scan() / FullScan() / SearchScan()
        │
        ▼
    TaskQueue 调度 ScanTask
        │
        ▼ (每个拍卖条目)
    ScanModule.NotifyAuction()
        ├── GatherScanModule → Gatherer.AddAuctionItemInfo() → StatisticDb
        ├── SniperScanModule → Sniper → 各策略.Snipe() → ScanDialog
        └── SearchScanModule → ScannerItemModel → ItemTable 显示

上架流程:
    Seller.SelectInventoryItem()
        │
        ▼
    Scanner.Scan(itemLink) → ScanSet (当前竞价情况)
        │
        ▼
    AutomaticPriceModel.Update() → 选择定价策略
        │
        ▼
    BuyoutModifier.ModifyBuyout() → 应用价格修改器
        │
        ▼
    Seller.PostAuction() → WoW API
```

---

## 七、文件统计

| 类别 | 文件数 |
|------|--------|
| Core | 11 |
| Gui | 5 |
| TaskQueue | 2 |
| Help | 1 |
| AuctionHouse | 6 |
| TooltipHook | 1 |
| OwnAuctions | 4 |
| Seller | 8 |
| Items | 2 |
| Scanner | 13 |
| Sniper | 7 |
| Statistic | 6 |
| Search | 2 |
| Disenchant | 1 |
| API | 1 |
| Locale | 12 |
| XML 模板 | 7 |
| **业务代码合计** | **~82 个 Lua 文件** |
