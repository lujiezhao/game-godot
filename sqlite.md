# Godot4 RPG游戏SQLite数据库设计文档

## 概述

本文档描述了基于提供的JSON数据结构为Godot4 RPG游戏项目设计的SQLite数据库架构。数据库将存储游戏的核心数据，包括游戏信息、章节、角色、地图、建筑、道具等。

## 项目结构

建议创建以下文件夹结构：

```
database/
├── sqlite_manager.gd          # 主数据库管理类
├── models/                    # 数据模型类
│   ├── game_model.gd         # 游戏数据模型
│   ├── character_model.gd    # 角色数据模型
│   ├── map_model.gd          # 地图数据模型
│   └── building_model.gd     # 建筑数据模型
├── repositories/              # 数据访问层
│   ├── game_repository.gd    # 游戏数据访问
│   ├── character_repository.gd # 角色数据访问
│   ├── map_repository.gd     # 地图数据访问
│   └── building_repository.gd # 建筑数据访问
├── migrations/                # 数据库迁移脚本
│   ├── create_tables.sql     # 创建表结构
│   └── seed_data.sql        # 初始数据
└── maps/                      # 地图JSON文件存储
	├── map_loader.gd         # 地图加载器
	└── data/                 # 地图数据文件夹
		├── map_001.json      # 具体地图文件
		└── map_002.json
```

## 数据库设计

### 1. 核心表结构

#### 1.1 游戏信息表 (games)
```sql
CREATE TABLE games (
	game_id TEXT PRIMARY KEY,
	name TEXT NOT NULL,
	category TEXT,
	background TEXT,
	intro TEXT,
	image_url TEXT,
	language TEXT,
	genre TEXT,
	user_id TEXT,
	moderation_level TEXT,
	background_musics TEXT, -- JSON存储
	use_shared_memory BOOLEAN DEFAULT FALSE,
	mechanics TEXT,
	operation_name TEXT,
	initialize_2d_status BOOLEAN DEFAULT FALSE,
	created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
	updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

#### 1.2 章节表 (chapters)
```sql
CREATE TABLE chapters (
	chapter_id TEXT PRIMARY KEY,
	game_id TEXT NOT NULL,
	name TEXT NOT NULL,
	background TEXT,
	intro TEXT,
	image_url TEXT,
	background_audio TEXT,
	ending_audio TEXT,
	map_url TEXT,
	background_musics TEXT, -- JSON存储
	no_goal BOOLEAN DEFAULT FALSE,
	goal_displayed TEXT,
	all_trigger_fail BOOLEAN DEFAULT FALSE,
	FOREIGN KEY (game_id) REFERENCES games(game_id)
);
```

#### 1.3 目标表 (goals)
```sql
CREATE TABLE goals (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	chapter_id TEXT NOT NULL,
	goal_key TEXT NOT NULL,
	goal_value TEXT,
	FOREIGN KEY (chapter_id) REFERENCES chapters(chapter_id)
);
```

#### 1.4 子目标表 (subgoals)
```sql
CREATE TABLE subgoals (
	subgoal_id TEXT PRIMARY KEY,
	goal_id INTEGER NOT NULL,
	subgoal TEXT,
	FOREIGN KEY (goal_id) REFERENCES goals(id)
);
```

#### 1.5 目标锚点表 (goal_anchors)
```sql
CREATE TABLE goal_anchors (
	anchor_id TEXT PRIMARY KEY,
	subgoal_id TEXT NOT NULL,
	affiliate TEXT,
	anchor_name TEXT,
	character_id TEXT,
	affiliate_type TEXT,
	anchor_init_value TEXT,
	anchor_goal_reached_value TEXT,
	FOREIGN KEY (subgoal_id) REFERENCES subgoals(subgoal_id)
);
```

#### 1.6 角色表 (characters)
```sql
CREATE TABLE characters (
	character_id TEXT PRIMARY KEY,
	chapter_id TEXT NOT NULL,
	name TEXT NOT NULL,
	type TEXT NOT NULL, -- 'npc' or 'player'
	avatar TEXT,
	phases TEXT, -- JSON存储
	voice_profile TEXT,
	opening_line TEXT,
	intro TEXT,
	character_tags TEXT, -- JSON存储
	image_references TEXT, -- JSON存储
	modules TEXT, -- JSON存储
	appearance TEXT,
	hp INTEGER DEFAULT 100,
	mp INTEGER DEFAULT 100,
	texture TEXT,
	unit_type TEXT,
	is_init BOOLEAN DEFAULT TRUE,
	spawn_x REAL,
	spawn_y REAL,
	talk_value TEXT,
	action_key TEXT,
	is_patrol BOOLEAN DEFAULT FALSE,
	patrol_range INTEGER DEFAULT 60,
	patrol_range_type INTEGER DEFAULT 0,
	emoji TEXT,
	emoji_desc TEXT,
	emoji_summary TEXT,
	action_id TEXT,
	base_position_x REAL,
	base_position_y REAL,
	talk_topic TEXT,
	talk_topic_emoji TEXT,
	arrived_target_id TEXT,
	still_time INTEGER DEFAULT 0,
	patrol_timer INTEGER DEFAULT 30000,
	current_x REAL,
	current_y REAL,
	functions TEXT,
	user_id TEXT, -- 仅用于玩家角色
	persona_id TEXT, -- 仅用于玩家角色
	control_type INTEGER, -- 仅用于玩家角色
	client_session_id TEXT, -- 仅用于玩家角色
	FOREIGN KEY (chapter_id) REFERENCES chapters(chapter_id)
);
```

#### 1.7 地图表 (maps)
```sql
CREATE TABLE maps (
	map_id TEXT PRIMARY KEY,
	game_id TEXT NOT NULL,
	chapter_id TEXT,
	name TEXT,
	map_file_path TEXT NOT NULL, -- 地图JSON文件路径
	is_active BOOLEAN DEFAULT TRUE,
	created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
	updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
	FOREIGN KEY (game_id) REFERENCES games(game_id),
	FOREIGN KEY (chapter_id) REFERENCES chapters(chapter_id)
);
```

**注意：地图数据 (map_data) 存储为独立的JSON文件**
- 地图的详细数据（瓦片数据、图层信息等）存储在独立的JSON文件中
- 数据库只存储地图的基本信息和文件路径引用
- 这样可以提高数据库性能，便于地图编辑器直接操作文件

#### 1.8 建筑表 (buildings)
```sql
CREATE TABLE buildings (
	building_id TEXT PRIMARY KEY,
	map_id TEXT NOT NULL,
	chapter_id TEXT NOT NULL,
	game_id TEXT NOT NULL,
	name TEXT NOT NULL,
	entity_id TEXT,
	user_id TEXT,
	category TEXT,
	appearance TEXT,
	width INTEGER,
	height INTEGER,
	original_width INTEGER,
	original_height INTEGER,
	spawn_x REAL,
	spawn_y REAL,
	x REAL NOT NULL,
	y REAL NOT NULL,
	texture TEXT,
	functions TEXT, -- JSON存储功能数组
	depth INTEGER DEFAULT 1,
	interaction TEXT, -- JSON存储交互数据
	is_init BOOLEAN DEFAULT TRUE,
	display_width INTEGER,
	display_height INTEGER,
	rotation REAL DEFAULT 0,
	visible BOOLEAN DEFAULT TRUE,
	FOREIGN KEY (map_id) REFERENCES maps(map_id),
	FOREIGN KEY (chapter_id) REFERENCES chapters(chapter_id),
	FOREIGN KEY (game_id) REFERENCES games(game_id)
);
```

#### 1.9 建筑属性表 (building_properties)
```sql
CREATE TABLE building_properties (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	building_id TEXT NOT NULL,
	property_name TEXT NOT NULL,
	property_type TEXT NOT NULL,
	property_value TEXT NOT NULL,
	FOREIGN KEY (building_id) REFERENCES buildings(building_id)
);
```

#### 1.10 道具表 (props)
```sql
CREATE TABLE props (
	prop_id TEXT PRIMARY KEY,
	game_id TEXT NOT NULL,
	chapter_id TEXT,
	name TEXT NOT NULL,
	type TEXT,
	description TEXT,
	image_url TEXT,
	properties TEXT, -- JSON存储属性
	x REAL,
	y REAL,
	is_active BOOLEAN DEFAULT TRUE,
	created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
	FOREIGN KEY (game_id) REFERENCES games(game_id),
	FOREIGN KEY (chapter_id) REFERENCES chapters(chapter_id)
);
```

#### 1.11 会话信息表 (sessions)
```sql
CREATE TABLE sessions (
	session_id TEXT PRIMARY KEY,
	channel_id TEXT,
	game_id TEXT NOT NULL,
	chapter_id TEXT,
	source TEXT,
	last_message_id TEXT,
	app_id TEXT,
	type INTEGER,
	status INTEGER,
	create_time DATETIME DEFAULT CURRENT_TIMESTAMP,
	update_time DATETIME DEFAULT CURRENT_TIMESTAMP,
	FOREIGN KEY (game_id) REFERENCES games(game_id),
	FOREIGN KEY (chapter_id) REFERENCES chapters(chapter_id)
);
```

#### 1.12 作者信息表 (authors)
```sql
CREATE TABLE authors (
	user_id TEXT PRIMARY KEY,
	name TEXT NOT NULL,
	picture TEXT,
	status INTEGER DEFAULT 1,
	provider TEXT,
	created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

#### 1.13 游戏交互统计表 (game_interactions)
```sql
CREATE TABLE game_interactions (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	game_id TEXT NOT NULL,
	played_count INTEGER DEFAULT 0,
	msg_count INTEGER DEFAULT 0,
	template_count INTEGER DEFAULT 0,
	chats_end_time DATETIME,
	last_play_time DATETIME,
	FOREIGN KEY (game_id) REFERENCES games(game_id)
);
```

### 2. 索引设计

```sql
-- 提高查询性能的索引
CREATE INDEX idx_chapters_game_id ON chapters(game_id);
CREATE INDEX idx_characters_chapter_id ON characters(chapter_id);
CREATE INDEX idx_characters_type ON characters(type);
CREATE INDEX idx_buildings_map_id ON buildings(map_id);
CREATE INDEX idx_buildings_chapter_id ON buildings(chapter_id);
CREATE INDEX idx_goals_chapter_id ON goals(chapter_id);
CREATE INDEX idx_subgoals_goal_id ON subgoals(goal_id);
CREATE INDEX idx_sessions_game_id ON sessions(game_id);
CREATE INDEX idx_props_game_id ON props(game_id);
CREATE INDEX idx_maps_game_id ON maps(game_id);
CREATE INDEX idx_maps_chapter_id ON maps(chapter_id);
```

## 数据库操作类设计

### 1. SQLiteManager (sqlite_manager.gd)
主数据库管理类，负责：
- 数据库连接管理
- 事务处理
- 错误处理
- 数据库初始化和迁移

### 2. Repository模式
每个主要实体都有对应的Repository类：
- GameRepository: 游戏CRUD操作
- CharacterRepository: 角色CRUD操作
- MapRepository: 地图索引管理和JSON文件操作
- BuildingRepository: 建筑CRUD操作

### 3. Model类
数据模型类定义数据结构和基本验证：
- GameModel
- CharacterModel
- MapModel
- BuildingModel

## 使用建议

### 1. Godot4插件要求
- 使用SQLite插件 (如 godot-sqlite)
- 确保插件支持Godot4

### 2. 数据序列化
- JSON字段使用Godot的JSON.stringify()和JSON.parse()
- 复杂对象可考虑使用Godot的序列化系统

### 3. 性能优化
- 对频繁查询的字段建立索引
- 使用事务批量操作
- 实现连接池管理
- 考虑数据分页加载

### 4. 数据备份
- 实现定期数据库备份
- 支持数据导入导出
- 版本控制和迁移管理

### 5. 安全考虑
- 使用参数化查询防止SQL注入
- 敏感数据加密存储
- 实现数据访问权限控制

## 扩展性设计

### 1. 模块化设计
- 每个功能模块独立的数据表
- 支持插件式功能扩展
- 灵活的配置系统

### 2. 多语言支持
- 文本内容国际化
- 支持多语言数据存储

### 3. 版本兼容性
- 数据库版本管理
- 平滑的数据迁移
- 向后兼容性考虑

## 地图文件管理

### 1. 地图JSON文件结构
地图数据单独存储为JSON文件，结构如下：
```json
{
	"map_id": "MPVY41DNJW",
	"width": 80,
	"height": 40,
	"tilewidth": 16,
	"tileheight": 16,
	"version": "1.10",
	"type": "map",
	"tiledversion": "1.10.0",
	"orientation": "orthogonal",
	"renderorder": "right-down",
	"nextlayerid": 11,
	"nextobjectid": 1,
	"compressionlevel": -1,
	"layers": [
		{
			"id": 0,
			"name": "Items",
			"type": "objectgroup",
			"objects": [...],
			"visible": true,
			"opacity": 1,
			"x": 0,
			"y": 0
		}
	]
}
```

### 2. MapLoader类设计
```gdscript
class_name MapLoader
extends RefCounted

static func load_map(map_id: String) -> Dictionary:
	# 从数据库获取地图文件路径
	# 加载并解析JSON文件
	# 返回地图数据

static func save_map(map_id: String, map_data: Dictionary) -> bool:
	# 将地图数据保存为JSON文件
	# 更新数据库中的文件路径引用

static func get_map_file_path(map_id: String) -> String:
	# 根据map_id生成文件路径
```

### 3. 地图缓存策略
- 内存中缓存当前使用的地图
- 支持异步加载大型地图文件
- 实现LRU缓存策略，自动释放不使用的地图

### 4. 优势
- **性能优化**：避免在数据库中存储大量瓦片数据
- **便于编辑**：地图编辑器可直接操作JSON文件
- **版本控制**：JSON文件易于进行版本控制
- **模块化**：地图数据与游戏逻辑数据分离

这个设计为Godot4 RPG游戏提供了完整的数据存储解决方案，支持复杂的游戏逻辑和数据管理需求。 
