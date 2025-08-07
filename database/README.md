# Godot4 RPG游戏 SQLite数据库系统

这是为Godot4 RPG游戏项目设计的完整SQLite数据库系统，支持游戏数据的存储、查询和管理。

## 🚀 特性

- **完整的数据模型**: 支持世界、游戏、角色、建筑、道具等所有游戏实体
- **类型安全**: 使用GDScript的类型系统确保数据一致性
- **JSON导入**: 支持从JSON文件批量导入游戏数据
- **事务支持**: 确保数据操作的原子性
- **索引优化**: 针对常用查询进行了性能优化
- **地图文件管理**: 独立的地图文件存储和管理系统

## 📁 文件结构

```
database/
├── sqlite_manager.gd              # 主数据库管理类（我们的封装）
├── json_importer.gd               # JSON数据导入器
├── database_test.gd               # 原测试脚本（有类型错误）
├── database_usage_example.gd      # 正确的godot-sqlite使用示例
├── models/                        # 数据模型类
│   ├── world_model.gd             # 世界数据模型
│   ├── game_model.gd              # 游戏数据模型
│   └── character_model.gd         # 角色数据模型
├── repositories/                  # 数据访问层
│   ├── world_repository.gd        # 世界数据访问
│   └── game_repository.gd         # 游戏数据访问
├── maps/                          # 地图系统
│   ├── map_loader.gd              # 地图加载器
│   └── data/                      # 地图数据存储目录
├── migrations/                    # 数据库迁移脚本
└── README.md                      # 本文档
```

## 🔧 安装和配置

### 1. 前置依赖

确保你的项目中已经安装了 `godot-sqlite` 插件：

```
addons/godot-sqlite/
```

### 2. 项目设置

确保 `godot-sqlite` 插件已正确安装并在项目设置中启用。

在项目设置中添加以下自动加载（可选，用于我们的封装）：

```
SQLiteManager: database/sqlite_manager.gd
```

### 3. 初始化数据库

#### 使用我们的封装管理器：
```gdscript
# 获取数据库管理器实例（自动初始化）
var db_manager = SQLiteManager.get_instance()

# 数据库会自动创建所有必要的表和索引
```

#### 直接使用 godot-sqlite API：
```gdscript
# 创建数据库实例
var db = SQLite.new()

# 设置数据库路径和选项
db.path = "user://my_game.db"
db.verbosity_level = SQLite.NORMAL
db.foreign_keys = true

# 打开数据库
if not db.open_db():
    push_error("无法打开数据库: " + db.error_message)
    return
```

## 📊 数据库架构

### 核心表结构

- **worlds** - 世界信息
- **games** - 游戏基本信息
- **chapters** - 章节数据
- **characters** - 角色数据（包含NPC和玩家）
- **buildings** - 建筑数据
- **props** - 道具数据
- **sessions** - 会话信息
- **authors** - 作者信息
- **game_interactions** - 游戏交互统计

### 关系表

- **goals** - 游戏目标
- **subgoals** - 子目标
- **goal_anchors** - 目标锚点
- **character_chapter_info** - 角色章节信息
- **chapter_participants** - 章节参与者
- **maps** - 地图记录

## 💻 使用示例

### 基本查询

#### 使用封装管理器：
```gdscript
# 查询所有游戏
var query = "SELECT * FROM games WHERE user_id = ?"
var results = SQLiteManager.execute_query(query, ["user_123"])

for game_data in results:
    var game = GameModel.new(game_data)
    print("游戏: " + game.name)
```

#### 直接使用 godot-sqlite：
```gdscript
# 创建数据库实例
var db = SQLite.new()
db.path = "user://my_game.db"
db.open_db()

# 参数化查询
var query = "SELECT * FROM games WHERE user_id = ?"
if db.query_with_bindings(query, ["user_123"]):
    for game_data in db.query_result:
        print("游戏: " + game_data.name)
else:
    print("查询失败: " + db.error_message)

db.close_db()
```

### 使用Repository模式

```gdscript
# 创建世界
var world_data = {
    "world_id": "WORLD_001",
    "name": "魔法世界",
    "user_id": "user_123"
}
var world = WorldModel.new(world_data)
var success = WorldRepository.create(world)

# 查询世界
var world = WorldRepository.get_by_world_id("WORLD_001")
if world:
    print("找到世界: " + world.name)
```

### JSON数据导入

#### 使用我们的导入器：
```gdscript
# 从JSON文件导入完整游戏数据
var success = JSONImporter.import_from_json_file("res://data/game_data.json")
if success:
    print("数据导入成功")
else:
    print("数据导入失败")
```

#### 使用 godot-sqlite 内置功能：
```gdscript
var db = SQLite.new()
db.path = "user://my_game.db"
db.open_db()

# 导出数据库到JSON
if db.export_to_json("user://backup.json"):
    print("导出成功")

# 从JSON导入数据库（会清空现有数据）
if db.import_from_json("user://backup.json"):
    print("导入成功")

db.close_db()
```

### 地图文件管理

```gdscript
# 保存地图数据
var map_data = {"tiles": [], "objects": []}
MapLoader.save_map("MAP_001", map_data)

# 加载地图数据
var loaded_map = MapLoader.load_map("MAP_001")
if not loaded_map.is_empty():
    print("地图加载成功")
```

### 事务处理

```gdscript
# 开始事务
SQLiteManager.begin_transaction()

try:
    # 执行多个操作
    var success1 = SQLiteManager.execute_non_query("INSERT INTO ...", [])
    var success2 = SQLiteManager.execute_non_query("UPDATE ...", [])
    
    if success1 and success2:
        SQLiteManager.commit_transaction()
        print("操作成功")
    else:
        SQLiteManager.rollback_transaction()
        print("操作失败，已回滚")
except:
    SQLiteManager.rollback_transaction()
    print("发生错误，已回滚")
```

## 🧪 测试

我们提供了两个测试/示例文件：

### 正确的使用示例
运行 `database_usage_example.gd` 查看正确的 godot-sqlite API使用方法：

```gdscript
# 将 database_usage_example.gd 添加到场景中
# 它会自动演示正确的 godot-sqlite 用法
```

### 我们的封装系统测试
```gdscript
# 使用我们的封装管理器（注意：需要先修复类型引用问题）
var tester = load("res://database/database_test.gd").new()
tester.test_database_system()
tester.check_database_status()
```

## ⚠️ 重要更新说明

根据 [godot-sqlite 官方文档](https://github.com/2shady4u/godot-sqlite)，我们已经修正了以下问题：

### 修正的API使用：
1. **数据库初始化**：使用 `db.path` 设置路径，然后调用 `db.open_db()`
2. **查询方法**：使用 `db.query()` 和 `db.query_with_bindings()`
3. **结果获取**：使用 `db.query_result` 属性
4. **错误处理**：使用 `db.error_message` 属性
5. **数据库关闭**：使用 `db.close_db()`

### 推荐的使用方式：
- **简单项目**：直接使用 `database_usage_example.gd` 中展示的 godot-sqlite API
- **复杂项目**：使用我们的封装系统，但需要先修复类型引用问题

## 📈 性能优化

### 索引

数据库已经为以下字段创建了索引：

- `worlds.user_id`
- `games.user_id`
- `characters.chapter_id`
- `characters.character_id`
- `buildings.map_id`
- 等等...

### 查询建议

1. **使用参数化查询**: 防止SQL注入并提高性能
2. **批量操作**: 使用事务包装批量插入/更新操作
3. **适当的LIMIT**: 避免一次性查询大量数据
4. **索引友好**: 查询条件优先使用已索引的字段

## 🔒 数据安全

### 备份策略

```gdscript
# 定期备份数据库文件
var db_path = "user://rpggame.db"
var backup_path = "user://backups/rpggame_backup_" + Time.get_datetime_string_from_system() + ".db"

var file = FileAccess.open(db_path, FileAccess.READ)
var backup_file = FileAccess.open(backup_path, FileAccess.WRITE)
backup_file.store_buffer(file.get_buffer(file.get_length()))
file.close()
backup_file.close()
```

### 数据验证

所有数据模型都包含 `validate()` 方法，确保数据完整性：

```gdscript
var game = GameModel.new(game_data)
if game.validate():
    GameRepository.create(game)
else:
    print("游戏数据验证失败")
```

## 🛠️ 扩展和自定义

### 添加新表

1. 在 `sqlite_manager.gd` 中添加创建表的SQL
2. 创建对应的Model类
3. 创建对应的Repository类
4. 更新JSON导入器（如果需要）

### 添加新字段

1. 使用 `ALTER TABLE` 语句（创建迁移脚本）
2. 更新对应的Model类
3. 更新Repository的查询语句

## ❓ 常见问题

### Q: 数据库文件在哪里？
A: 数据库文件存储在 `user://rpggame.db`，这是Godot的用户数据目录。

### Q: 如何重置数据库？
A: 删除 `user://rpggame.db` 文件，下次运行时会重新创建。

### Q: 地图数据为什么单独存储？
A: 地图数据通常很大，单独存储可以避免数据库膨胀，并提供更好的性能。

### Q: 如何处理数据迁移？
A: 在 `migrations/` 目录下创建迁移脚本，在数据库初始化时执行。

## 📝 更新日志

### v1.0.0
- 初始版本
- 完整的数据库架构
- JSON导入功能
- 基本的CRUD操作
- 地图文件管理系统

## 🤝 贡献

欢迎提交Issue和Pull Request来改进这个数据库系统！

## 📄 许可证

本项目采用MIT许可证。 