# 角色数据架构重新设计说明

## 🎯 问题分析

### 原始设计的问题
1. **角色绑定到章节**：角色数据存储在 `characters` 表中，通过 `chapter_id` 绑定到特定章节
2. **无法跨章节复用**：同一个角色无法在不同章节中使用，需要重复创建
3. **数据冗余**：相同角色的基础配置在多个章节中重复存储
4. **管理复杂**：角色的基础设定和运行时状态混合在一起

### 用户需求
- 角色应该属于 **World** 级别，而不是 Chapter 级别
- 不同的 Chapter 可以选择 World 中的任何角色加入
- 保持角色在不同章节中的独立运行时状态

## 🔧 新的设计方案

### 核心思想：分离基础配置和运行时状态

```
World (世界)
├── Characters (角色基础配置)
│   ├── Character A (基础AI设定、外观、属性等)
│   ├── Character B
│   └── Character C
└── Games (游戏)
    └── Chapters (章节)
        ├── Chapter 1
        │   ├── Character Instance A (运行时状态：位置、血量等)
        │   └── Character Instance B (运行时状态)
        └── Chapter 2
            ├── Character Instance A (独立的运行时状态)
            └── Character Instance C (运行时状态)
```

## 📊 数据库表结构

### 1. 角色基础表 (characters) - 重新设计
```sql
CREATE TABLE characters (
    id INTEGER PRIMARY KEY,
    character_id TEXT UNIQUE NOT NULL,
    world_id TEXT NOT NULL,  -- 从 chapter_id 改为 world_id
    name TEXT NOT NULL,
    type TEXT NOT NULL,
    -- 基础外观和配置
    avatar TEXT,
    texture TEXT,
    appearance TEXT,
    -- AI和创作者配置
    max_epochs TEXT DEFAULT "90",
    prompt TEXT,
    plugins TEXT,
    model_config TEXT,
    pronouns TEXT,
    background TEXT,
    traits TEXT,
    -- 其他基础配置...
    FOREIGN KEY (world_id) REFERENCES worlds(world_id)
);
```

### 2. 章节角色实例表 (chapter_character_instances) - 新增
```sql
CREATE TABLE chapter_character_instances (
    id INTEGER PRIMARY KEY,
    chapter_id TEXT NOT NULL,
    character_id TEXT NOT NULL,
    -- 运行时状态
    hp INTEGER DEFAULT 100,
    mp INTEGER DEFAULT 100,
    spawn_x REAL,
    spawn_y REAL,
    current_x REAL,
    current_y REAL,
    is_patrol BOOLEAN DEFAULT FALSE,
    patrol_range INTEGER DEFAULT 60,
    -- 章节特定配置覆盖
    chapter_specific_config TEXT, -- JSON格式
    -- 玩家控制相关
    control_type INTEGER,
    client_session_id TEXT,
    FOREIGN KEY (chapter_id) REFERENCES chapters(chapter_id),
    FOREIGN KEY (character_id) REFERENCES characters(character_id),
    UNIQUE(chapter_id, character_id)
);
```

## 🎮 使用场景示例

### 场景1：创建角色
```gdscript
# 在世界级别创建角色
var character = CharacterModel.new({
    "character_id": "CHAR_001",
    "world_id": "WORLD_001",
    "name": "勇敢的骑士",
    "type": "npc",
    "texture": "knight.png",
    "background": "来自北方的骑士",
    "pronouns": "male"
})

# 保存到 characters 表（世界级别）
CharacterRepository.create(character)
```

### 场景2：在章节中使用角色
```gdscript
# 在章节1中使用这个角色
var instance1 = ChapterCharacterInstanceModel.new({
    "chapter_id": "CHAPTER_001",
    "character_id": "CHAR_001",
    "hp": 100,
    "spawn_x": 100.0,
    "spawn_y": 200.0,
    "is_patrol": true,
    "patrol_range": 50
})

# 在章节2中也使用同一个角色，但有不同的状态
var instance2 = ChapterCharacterInstanceModel.new({
    "chapter_id": "CHAPTER_002", 
    "character_id": "CHAR_001",
    "hp": 80,  # 不同的血量
    "spawn_x": 300.0,  # 不同的位置
    "spawn_y": 400.0,
    "is_patrol": false  # 不同的行为
})
```

### 场景3：获取章节中的完整角色数据
```gdscript
# 获取角色基础配置
var character = CharacterRepository.get_by_character_id("CHAR_001")

# 获取角色在特定章节的实例状态
var instance = ChapterCharacterInstanceRepository.get_by_chapter_and_character(
    "CHAPTER_001", "CHAR_001"
)

# 组合使用
print("角色名称：", character.name)
print("角色背景：", character.background) 
print("当前血量：", instance.hp)
print("当前位置：", instance.get_current_position())
```

## 🔄 数据迁移考虑

### 从旧结构迁移到新结构
1. **提取基础配置**：将现有 `characters` 表中的基础配置数据迁移到新的 `characters` 表
2. **创建实例数据**：将运行时状态数据迁移到 `chapter_character_instances` 表
3. **更新外键关系**：将 `chapter_id` 关系改为 `world_id` 关系

## ✅ 新设计的优势

### 1. **角色复用**
- 一个角色可以在多个章节中使用
- 减少数据冗余和管理复杂度

### 2. **状态隔离**
- 每个章节中的角色有独立的运行时状态
- 不会相互影响

### 3. **配置灵活性**
- 支持章节级别的配置覆盖
- 基础配置和运行时状态清晰分离

### 4. **易于管理**
- 角色管理在世界级别
- 实例管理在章节级别
- 职责清晰，易于维护

### 5. **向后兼容**
- 可以通过查询两个表来重建原有的完整角色数据
- API 层面可以保持兼容

## 🛠️ 相关文件更新

已更新的文件：
- ✅ `sqlite.md` - 数据库表结构设计
- ✅ `database/sqlite_manager.gd` - 表创建和索引
- ✅ `database/models/character_model.gd` - 角色基础模型
- ✅ `database/models/chapter_character_instance_model.gd` - 章节实例模型

需要更新的文件：
- 🔄 `database/repositories/character_repository.gd` - 角色数据访问层
- 🔄 `database/json_importer.gd` - JSON数据导入逻辑
- 🔄 相关的查询和业务逻辑

## 🎯 下一步行动

1. **更新Repository层**：修改Character相关的数据访问逻辑
2. **修改JSON导入器**：适配新的数据结构
3. **创建迁移脚本**：从旧结构迁移到新结构
4. **更新业务逻辑**：修改游戏中使用角色数据的相关代码

这个新设计完美解决了角色跨章节复用的需求，同时保持了数据的一致性和灵活性！ 