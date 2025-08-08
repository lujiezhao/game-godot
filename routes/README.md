# HTTP路由系统

这是一个为Godot4 RPG游戏设计的HTTP路由系统，基于现有的`http_server.gd`进行扩展，提供模块化的API服务。

## 📁 文件结构

```
routes/
├── README.md                    # 本文档
├── route_manager.gd             # 路由管理器 - 核心路由分发逻辑
├── test_routes.gd               # 测试脚本 - 验证路由系统功能
└── services/
    └── game_data_service.gd     # 游戏数据服务 - 从数据库导出游戏数据
```

## 🚀 核心功能

### 1. 路由管理器 (`RouteManager`)
- **功能**: 负责HTTP请求的分发和路由处理
- **特性**:
  - 支持查询参数解析 (`?game_id=xxx`)
  - 自动JSON响应格式化
  - CORS跨域支持
  - 错误处理和404处理
  - 动态路由注册

### 2. 游戏数据服务 (`GameDataService`)
- **功能**: 从SQLite数据库查询数据并拼装成GY3MCVANW.json格式
- **特性**:
  - 根据`game_id`查询完整游戏数据
  - 支持新的角色架构（world级别角色 + chapter级别实例）
  - 自动处理JSON字段解析
  - 完整的数据关联查询

## 🛠️ 已注册的API端点

| 方法 | 路径 | 描述 | 参数 |
|------|------|------|------|
| GET | `/health` | 健康检查 | 无 |
| GET | `/api/game/export` | 导出游戏数据 | `game_id` (必需) |

## 📖 使用示例

### 启动HTTP服务器
```gdscript
# 在autoload的http_server中会自动初始化路由系统
# 手动启动服务器:
get_node("/root/HttpServer").start_http_server()
```

### API调用示例

#### 1. 健康检查
```bash
curl http://localhost:9080/health
```
**响应**: `🟢 HTTP Server is running`

#### 2. 导出游戏数据
```bash
curl "http://localhost:9080/api/game/export?game_id=GY3MCVANW"
```
**响应**: 完整的游戏JSON数据（GY3MCVANW.json格式）

### 程序内调用示例
```gdscript
# 创建路由管理器
var route_manager = RouteManager.new()

# 处理请求
var response = route_manager.handle_request(
    "GET", 
    "/api/game/export?game_id=GY3MCVANW", 
    ""
)
print(response)  # 输出HTTP响应字符串
```

## 🎮 游戏数据导出详解

### 导出的数据结构
游戏数据服务会从数据库中查询并拼装以下结构：

```json
{
  "game_info": {
    "name": "游戏名称",
    "game_id": "GY3MCVANW",
    "category": "detective",
    "background": "游戏背景",
    "intro": "游戏介绍",
    "chapters": [
      {
        "name": "章节名称",
        "chapter_id": "XWrO7fILL",
        "goals": [...],
        "characters": [...],
        "players": [...]
      }
    ]
  }
}
```

### 数据来源表
- **games**: 游戏基本信息
- **chapters**: 章节信息
- **goals/subgoals/goal_anchors**: 目标系统
- **characters**: 角色基本信息（world级别）
- **chapter_character_instances**: 角色章节实例（运行时数据）

### 角色数据合并逻辑
1. 从`characters`表获取角色基本信息（世界级别）
2. 从`chapter_character_instances`表获取章节特定的运行时数据
3. 合并`chapter_specific_config`中的章节特定配置
4. 生成完整的角色JSON结构

## 🧪 测试和调试

### 运行测试
```gdscript
# 加载测试脚本
var tester = load("res://routes/test_routes.gd").new()
add_child(tester)

# 测试会自动运行，或者手动触发:
# 按 H 键启动HTTP服务器
# 按 T 键重新运行路由测试
```

### 测试内容
- ✅ 路由注册和分发
- ✅ 查询参数解析
- ✅ 健康检查端点
- ✅ 游戏数据导出（有效/无效game_id）
- ✅ 404错误处理
- ✅ JSON响应格式化

## 🔧 扩展路由系统

### 添加新的API端点

1. **创建服务文件**
```gdscript
# routes/services/new_service.gd
class_name NewService
extends RefCounted

static func handle_request(context: Dictionary) -> Dictionary:
    # 处理逻辑
    return {"message": "新服务响应"}
```

2. **注册路由**
```gdscript
# 在route_manager.gd的_register_routes()中添加:
register_route("GET", "/api/new/endpoint", _handle_new_service)

# 添加处理器方法:
func _handle_new_service(context: Dictionary) -> Dictionary:
    var service_script = load("res://routes/services/new_service.gd")
    return service_script.handle_request(context)
```

### 支持POST请求
路由系统已支持POST请求，只需在注册时指定方法：
```gdscript
register_route("POST", "/api/data/create", _handle_create_data)
```

### 添加中间件
可以在`RouteManager.handle_request()`中添加中间件逻辑：
```gdscript
# 在路由处理前添加认证、日志等中间件
func handle_request(method: String, path: String, full_request: String) -> String:
    # 认证中间件
    if not _authenticate_request(full_request):
        return _build_response(401, "Unauthorized", "text/plain", "Access denied")
    
    # 日志中间件
    _log_request(method, path)
    
    # 继续原有的路由处理逻辑...
```

## 📋 数据库依赖

该路由系统依赖以下数据库组件：
- `SQLiteManager`: 数据库连接管理
- 完整的游戏数据库架构（见`sqlite.md`）
- 新的角色架构支持（world级别角色 + chapter级别实例）

确保在使用前已正确初始化数据库并导入了测试数据。

## 🔍 故障排除

### 常见问题

1. **路由管理器未初始化**
   - 检查`http_server.gd`中的`_route_manager`是否正确创建
   - 确保在`_ready()`中调用了路由管理器初始化

2. **数据库连接失败**
   - 检查`SQLiteManager`是否正确初始化
   - 确认数据库文件存在且有正确的权限

3. **游戏数据导出为空**
   - 检查数据库中是否有对应的`game_id`数据
   - 确认数据库架构是否符合预期

4. **JSON解析错误**
   - 检查数据库中存储的JSON字段格式是否正确
   - 查看控制台中的解析警告信息

### 调试技巧

1. **启用详细日志**: 路由系统会输出详细的处理日志
2. **使用测试脚本**: `test_routes.gd`提供全面的功能测试
3. **浏览器测试**: 直接在浏览器中访问API端点
4. **Postman测试**: 使用API测试工具进行更复杂的测试

## 🎯 后续计划

- [ ] 添加认证和授权中间件
- [ ] 支持文件上传API
- [ ] 添加实时WebSocket支持
- [ ] 实现API版本控制
- [ ] 添加请求限流和缓存
- [ ] 支持多格式响应（XML、CSV等） 