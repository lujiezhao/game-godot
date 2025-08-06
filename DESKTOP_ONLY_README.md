# 🖥️ 桌面版RPG游戏

## 📋 **项目说明**

这是一个专注于**桌面平台**的多人RPG游戏，使用Godot 4引擎开发。

### ✅ **支持的平台**
- Windows
- macOS  
- Linux
- 专用服务器

### ❌ **不支持的平台**
- Web浏览器
- 移动设备（暂未测试）

## 🔧 **技术架构**

### 网络架构
- **统一ENet协议** - 所有平台使用相同的网络库
- **客户端-服务器模式** - 支持多人在线游戏
- **专用服务器支持** - 可以导出独立的服务器

### OAuth认证
- **Google OAuth 2.0** - 用户登录和身份验证
- **桌面平台优化** - 本地TCP服务器处理OAuth回调
- **服务端验证** - 安全的用户信息获取

## 🚀 **快速开始**

### 1. 环境要求
- Godot 4.x
- 有效的Google OAuth凭据

### 2. 配置OAuth
在 `source/login_button.gd` 中配置你的OAuth凭据：
```gdscript
var oauth_credentials = {
    "oauth_client_id": "你的客户端ID",
    "oauth_client_secret": "你的客户端密钥",
    "oauth_auth_server": "https://accounts.google.com/o/oauth2/auth",
    "oauth_token_req": "https://oauth2.googleapis.com/token",
    "oauth_token_key": Config.TOKEN_KEY,
    "oauth_redirect_uri": "http://localhost:2567"
}
```

### 3. 运行游戏
1. **本地测试**：直接在Godot编辑器中运行
2. **多人测试**：
   - 启动一个实例作为服务器
   - 启动另一个实例作为客户端连接

## 🎮 **游戏功能**

- ✅ OAuth登录系统
- ✅ 多人联机支持
- ✅ 角色同步
- ✅ 地图系统
- ✅ NPC交互

## 📁 **项目结构**

```
├── source/                 # 游戏核心代码
│   ├── main_menu.gd        # 主菜单和网络设置
│   ├── login_button.gd     # OAuth登录
│   └── ...
├── addons/godot_auth/      # OAuth插件
│   └── tools/
│       ├── oauth.gd        # 桌面OAuth实现
│       └── oauth_manager.gd # OAuth管理器
├── autoload/               # 全局脚本
├── component/              # 游戏组件
└── assets/                 # 游戏资源
```

## 🛠️ **开发说明**

### 网络连接
- 默认端口：9528
- 使用ENet协议进行客户端-服务器通信
- 支持专用服务器模式

### OAuth流程
1. 用户点击登录按钮
2. 打开浏览器进行Google OAuth认证
3. 本地TCP服务器接收回调
4. 获取用户令牌和信息
5. 连接游戏服务器时同步用户数据

## 🔧 **故障排除**

### 常见问题
1. **OAuth回调失败**：检查Google Cloud Console中的重定向URI设置
2. **网络连接失败**：确保防火墙允许端口9528
3. **用户信息获取失败**：检查网络连接和OAuth权限

### 调试工具
- 使用 `NetworkConfig.print_network_info()` 查看网络配置
- 检查控制台输出获取详细错误信息

## 📝 **更新日志**

### 2024-12-xx - 桌面专用版本
- 移除了Web平台支持
- 简化了网络架构
- 优化了OAuth流程
- 清理了冗余代码

## 📧 **联系方式**

如有问题请通过项目Issues反馈。

---

**注意**：此版本专为桌面平台优化，不支持Web浏览器运行。 