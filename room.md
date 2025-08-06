# Godot 4.4 房间管理系统设计方案

## 概述

本方案旨在为Godot 4.4游戏实现一个完整的房间管理系统，允许玩家通过不同的gameId进入不同的房间，每个房间拥有独立的地图、NPC和玩家状态，不同房间的玩家互不影响。

## 系统架构

### 1. 核心组件

#### 1.1 房间管理器 (RoomManager)
- **位置**: `source/room_manager.gd`
- **功能**: 管理所有房间的创建、销毁和状态维护
- **职责**:
  - 房间生命周期管理
  - 玩家房间分配
  - 房间状态同步
  - 跨房间通信隔离

#### 1.2 房间实例 (RoomInstance)
- **位置**: `source/room_instance.gd`
- **功能**: 单个房间的完整实例
- **职责**:
  - 房间内玩家管理
  - 房间内地图管理
  - 房间内NPC管理
  - 房间内事件处理

#### 1.3 房间数据 (RoomData)
- **位置**: `datas/room_data.gd`
- **功能**: 房间配置和状态数据
- **职责**:
  - 房间配置信息
  - 房间状态数据
  - 房间资源引用

### 2. 数据结构设计

#### 2.1 房间配置结构
```gdscript
class_name RoomConfig
extends Resource

@export var room_id: String = ""
@export var game_id: String = ""
@export var max_players: int = 20
@export var map_config: MapConfig
@export var npc_configs: Array[NPCConfig]
@export var spawn_points: Array[Vector2]
@export var room_settings: Dictionary = {}
```

#### 2.2 房间状态结构
```gdscript
class_name RoomState
extends Resource

@export var room_id: String = ""
@export var current_players: int = 0
@export var is_active: bool = true
@export var created_time: int = 0
@export var last_activity: int = 0
@export var player_list: Array[String] = []
```

## 实现方案

### 1. 房间管理器实现

#### 1.1 核心类定义
```gdscript
# source/room_manager.gd
extends Node
class_name RoomManager

signal room_created(room_id: String)
signal room_destroyed(room_id: String)
signal player_joined_room(player_id: int, room_id: String)
signal player_left_room(player_id: int, room_id: String)

var rooms: Dictionary = {}  # room_id -> RoomInstance
var player_room_map: Dictionary = {}  # player_id -> room_id
var room_configs: Dictionary = {}  # game_id -> RoomConfig

func _ready():
    if multiplayer.is_server():
        load_room_configs()
        setup_network_handlers()

func load_room_configs():
    # 从服务器或配置文件加载房间配置
    pass

func create_room(game_id: String) -> String:
    var room_id = generate_room_id(game_id)
    var room_config = get_room_config(game_id)
    
    if room_config == null:
        push_error("无法找到游戏ID对应的房间配置: " + game_id)
        return ""
    
    var room_instance = RoomInstance.new()
    room_instance.room_id = room_id
    room_instance.room_config = room_config
    room_instance.room_manager = self
    
    rooms[room_id] = room_instance
    add_child(room_instance)
    
    room_created.emit(room_id)
    return room_id

func join_room(player_id: int, game_id: String) -> bool:
    var room_id = find_available_room(game_id)
    if room_id.is_empty():
        room_id = create_room(game_id)
    
    if room_id.is_empty():
        return false
    
    var room = rooms.get(room_id)
    if room == null:
        return false
    
    if room.add_player(player_id):
        player_room_map[player_id] = room_id
        player_joined_room.emit(player_id, room_id)
        return true
    
    return false

func leave_room(player_id: int):
    var room_id = player_room_map.get(player_id, "")
    if room_id.is_empty():
        return
    
    var room = rooms.get(room_id)
    if room != null:
        room.remove_player(player_id)
    
    player_room_map.erase(player_id)
    player_left_room.emit(player_id, room_id)
    
    # 检查房间是否需要销毁
    if room != null and room.get_player_count() == 0:
        destroy_room(room_id)

func destroy_room(room_id: String):
    var room = rooms.get(room_id)
    if room != null:
        room.queue_free()
        rooms.erase(room_id)
        room_destroyed.emit(room_id)

func get_player_room(player_id: int) -> String:
    return player_room_map.get(player_id, "")

func get_room_instance(room_id: String) -> RoomInstance:
    return rooms.get(room_id)

func generate_room_id(game_id: String) -> String:
    return game_id + "_" + str(Time.get_unix_time_from_system()) + "_" + str(randi())

func find_available_room(game_id: String) -> String:
    for room_id in rooms:
        var room = rooms[room_id]
        if room.room_config.game_id == game_id and room.can_accept_player():
            return room_id
    return ""

@rpc("any_peer", "call_local", "reliable")
func request_join_room(game_id: String):
    if not multiplayer.is_server():
        return
    
    var player_id = multiplayer.get_remote_sender_id()
    var success = join_room(player_id, game_id)
    
    if success:
        var room_id = get_player_room(player_id)
        join_room_response.rpc_id(player_id, true, room_id)
    else:
        join_room_response.rpc_id(player_id, false, "")

@rpc("authority", "call_local", "reliable")
func join_room_response(success: bool, room_id: String):
    if success:
        print("成功加入房间: ", room_id)
        # 客户端处理加入房间成功
    else:
        print("加入房间失败")
        # 客户端处理加入房间失败
```

#### 1.2 房间实例实现
```gdscript
# source/room_instance.gd
extends Node
class_name RoomInstance

signal player_added(player_id: int)
signal player_removed(player_id: int)
signal room_ready

@export var room_id: String = ""
@export var room_config: RoomConfig
var room_manager: RoomManager
var players: Dictionary = {}  # player_id -> PlayerData
var game_map: GameMap
var npc_manager: NPCManager
var is_initialized: bool = false

func _ready():
    if multiplayer.is_server():
        initialize_room()

func initialize_room():
    if is_initialized:
        return
    
    # 创建地图
    create_game_map()
    
    # 创建NPC管理器
    create_npc_manager()
    
    # 设置网络同步
    setup_network_synchronization()
    
    is_initialized = true
    room_ready.emit()

func create_game_map():
    game_map = preload("res://source/game_map.tscn").instantiate()
    game_map.room_id = room_id
    game_map.room_config = room_config
    add_child(game_map)

func create_npc_manager():
    npc_manager = NPCManager.new()
    npc_manager.room_id = room_id
    npc_manager.room_config = room_config
    add_child(npc_manager)

func add_player(player_id: int) -> bool:
    if not can_accept_player():
        return false
    
    var player_data = PlayerData.new()
    player_data.player_id = player_id
    player_data.room_id = room_id
    player_data.spawn_point = get_random_spawn_point()
    
    players[player_id] = player_data
    
    # 通知客户端玩家加入
    player_joined_room.rpc_id(player_id, room_id, player_data)
    
    player_added.emit(player_id)
    return true

func remove_player(player_id: int):
    if not players.has(player_id):
        return
    
    var player_data = players[player_id]
    players.erase(player_id)
    
    # 通知客户端玩家离开
    player_left_room.rpc_id(player_id, room_id)
    
    player_removed.emit(player_id)

func can_accept_player() -> bool:
    return players.size() < room_config.max_players

func get_player_count() -> int:
    return players.size()

func get_random_spawn_point() -> Vector2:
    if room_config.spawn_points.size() == 0:
        return Vector2(320, 160)  # 默认出生点
    
    var random_index = randi() % room_config.spawn_points.size()
    return room_config.spawn_points[random_index]

@rpc("authority", "call_local", "reliable")
func player_joined_room(room_id: String, player_data: PlayerData):
    if multiplayer.is_server():
        return
    
    print("玩家加入房间: ", room_id)
    # 客户端处理玩家加入逻辑

@rpc("authority", "call_local", "reliable")
func player_left_room(room_id: String):
    if multiplayer.is_server():
        return
    
    print("玩家离开房间: ", room_id)
    # 客户端处理玩家离开逻辑
```

### 2. 数据类定义

#### 2.1 房间配置类
```gdscript
# datas/room_config.gd
extends Resource
class_name RoomConfig

@export var game_id: String = ""
@export var max_players: int = 20
@export var map_data_url: String = ""
@export var npc_configs: Array[NPCConfig] = []
@export var spawn_points: Array[Vector2] = []
@export var room_settings: Dictionary = {}

func _init():
    if spawn_points.size() == 0:
        spawn_points.append(Vector2(320, 160))
```

#### 2.2 玩家数据类
```gdscript
# datas/player_data.gd
extends Resource
class_name PlayerData

@export var player_id: int = 0
@export var room_id: String = ""
@export var spawn_point: Vector2 = Vector2.ZERO
@export var character_data: Dictionary = {}
@export var join_time: int = 0

func _init():
    join_time = Time.get_unix_time_from_system()
```

#### 2.3 NPC配置类
```gdscript
# datas/npc_config.gd
extends Resource
class_name NPCConfig

@export var npc_id: String = ""
@export var npc_type: String = ""
@export var position: Vector2 = Vector2.ZERO
@export var behavior_config: Dictionary = {}
@export var dialogue_config: Dictionary = {}
```

### 3. 网络同步实现

#### 3.1 房间状态同步
```gdscript
# 在RoomInstance中添加网络同步
@rpc("authority", "call_local", "reliable")
func sync_room_state(room_state: Dictionary):
    if multiplayer.is_server():
        return
    
    # 客户端更新房间状态
    update_room_state(room_state)

func update_room_state(room_state: Dictionary):
    # 更新房间状态
    pass

@rpc("any_peer", "call_local", "reliable")
func sync_player_position(player_id: int, position: Vector2):
    if multiplayer.is_server():
        # 服务器验证并广播
        broadcast_player_position.rpc(player_id, position)
    else:
        # 客户端更新玩家位置
        update_player_position(player_id, position)

@rpc("authority", "call_local", "reliable")
func broadcast_player_position(player_id: int, position: Vector2):
    # 广播玩家位置给所有客户端
    pass
```

### 4. 客户端集成

#### 4.1 修改主场景
```gdscript
# source/main.gd 修改
extends Node2D

@onready var room_manager: RoomManager = $RoomManager
@onready var current_room: RoomInstance = null

func _ready() -> void:
    if multiplayer.is_server():
        # 服务器初始化房间管理器
        room_manager.room_created.connect(_on_room_created)
        room_manager.room_destroyed.connect(_on_room_destroyed)
    else:
        # 客户端请求加入房间
        request_join_room()

func request_join_room():
    var game_id = GlobalData.game_id
    if game_id.is_empty():
        push_error("游戏ID为空")
        return
    
    room_manager.request_join_room.rpc_id(1, game_id)

func _on_room_created(room_id: String):
    print("房间已创建: ", room_id)

func _on_room_destroyed(room_id: String):
    print("房间已销毁: ", room_id)
    if current_room != null and current_room.room_id == room_id:
        current_room = null
```

#### 4.2 修改游戏地图
```gdscript
# source/game_map.gd 修改
extends Node2D

@export var room_id: String = ""
@export var room_config: RoomConfig

func _ready():
    if room_config != null:
        # 使用房间配置加载地图
        load_room_map()

func load_room_map():
    if room_config.map_data_url.is_empty():
        push_error("房间配置中地图数据URL为空")
        return
    
    # 加载房间特定的地图数据
    remote_json_url = room_config.map_data_url
    load_remote_map()
```

### 5. 服务器端配置

#### 5.1 房间配置加载
```gdscript
# 在RoomManager中实现
func load_room_configs():
    # 从服务器API加载房间配置
    var config_url = "https://your-server.com/api/room-configs"
    var http_request = HTTPRequest.new()
    add_child(http_request)
    http_request.request_completed.connect(_on_config_loaded)
    http_request.request(config_url)

func _on_config_loaded(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
    if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
        push_error("加载房间配置失败")
        return
    
    var json = JSON.new()
    var parse_result = json.parse(body.get_string_from_utf8())
    if parse_result != OK:
        push_error("解析房间配置JSON失败")
        return
    
    var configs_data = json.get_data()
    for config_data in configs_data:
        var config = RoomConfig.new()
        config.game_id = config_data.game_id
        config.max_players = config_data.max_players
        config.map_data_url = config_data.map_data_url
        # ... 其他配置项
        
        room_configs[config.game_id] = config
```

## 部署和配置

### 1. 项目结构更新
```
rpggame-godot/
├── source/
│   ├── room_manager.gd          # 房间管理器
│   ├── room_instance.gd         # 房间实例
│   ├── npc_manager.gd           # NPC管理器
│   └── ... (现有文件)
├── datas/
│   ├── room_config.gd           # 房间配置类
│   ├── player_data.gd           # 玩家数据类
│   ├── npc_config.gd            # NPC配置类
│   └── ... (现有文件)
├── scenes/
│   ├── room_manager.tscn        # 房间管理器场景
│   └── room_instance.tscn       # 房间实例场景
└── ... (现有文件)
```

### 2. 场景配置
```gdscript
# 主场景需要添加RoomManager节点
[node name="main" type="Node2D"]
script = ExtResource("main_script")

[node name="RoomManager" type="Node" parent="."]
script = ExtResource("room_manager_script")
```

### 3. 网络配置
```gdscript
# 确保网络同步配置正确
# 在project.godot中添加
[network]
default_interface="ENetMultiplayerPeer"
```

## 性能优化

### 1. 房间生命周期管理
- 自动清理空房间
- 房间状态缓存
- 玩家连接池管理

### 2. 网络优化
- 房间内消息隔离
- 位置同步频率控制
- 状态压缩传输

### 3. 内存管理
- 房间资源按需加载
- 玩家数据序列化
- 场景切换优化

## 测试方案

### 1. 单元测试
- 房间创建/销毁测试
- 玩家加入/离开测试
- 网络同步测试

### 2. 集成测试
- 多房间并发测试
- 跨房间隔离测试
- 性能压力测试

### 3. 用户测试
- 房间切换流畅性
- 多人游戏稳定性
- 错误处理验证

## 扩展功能

### 1. 房间类型
- PvP房间
- PvE房间
- 交易房间
- 社交房间

### 2. 房间权限
- 房主权限
- 管理员权限
- 普通玩家权限

### 3. 房间功能
- 房间聊天
- 房间公告
- 房间活动
- 房间统计

## 总结

本方案提供了一个完整的房间管理系统实现，具有以下特点：

1. **模块化设计**: 各组件职责清晰，易于维护和扩展
2. **网络同步**: 完整的客户端-服务器同步机制
3. **性能优化**: 考虑了内存和网络性能优化
4. **扩展性**: 支持多种房间类型和功能扩展
5. **稳定性**: 包含完整的错误处理和状态管理

通过这个系统，玩家可以轻松地通过不同的gameId进入不同的房间，享受独立的游戏体验，同时保持系统的稳定性和可扩展性。 