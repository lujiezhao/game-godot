# Web OAuth 快速开始指南

## 🚀 一分钟完成Web登录

### 第1步：点击登录 (5秒)
在Godot中点击 **"Sign In"** 按钮

控制台输出：
```
Web平台OAuth流程：
1. 系统将尝试自动跳转到授权页面
2. 完成授权后，在回调页面复制授权码  
3. 在控制台中执行: get_node("LoginButton").web_auth_code("授权码")
4. 或者使用: get_node("LoginButton").input_auth_code("授权码")
自动跳转成功
```

### 第2步：Google授权 (10秒)
- ✅ 浏览器自动打开Google授权页面
- ✅ 选择你的Google账户并点击"允许"

### 第3步：复制命令 (5秒)
授权成功后的回调页面：

![回调页面示例]
```
✅ 授权成功！

📋 请复制以下授权码并在Godot控制台中使用：
[绿色] 4/0AVMBsJh1hHwMJA-QGA0WxvCnXdqDz4YhvxqNDBcNbp1O4qukQlKLEuOplFmGY3ojQ41l9Q

📋 在Godot控制台中选择一个命令执行：
[橙色] get_node("LoginButton").auth("4/0AVMBsJh1hHwMJA-QGA0...")      👈 推荐
[蓝色] get_node("LoginButton").web_auth_code("4/0AVMBsJh1hHwMJA-QGA0...")

[📋 复制简化命令] [📋 复制完整命令] [📋 仅复制授权码]
```

**👆 点击 "📋 复制简化命令" 按钮**

### 第4步：执行命令 (5秒)
1. 切换到Godot窗口
2. 在控制台粘贴并按回车
3. 完成！

## 🎯 关键操作

### 最重要的一步
在回调页面点击 **"📋 复制简化命令"** 按钮，然后在Godot控制台粘贴执行。

### 三种命令选择

| 命令 | 长度 | 推荐度 |
|------|------|--------|
| `get_node("LoginButton").auth("...")` | 短 | ⭐⭐⭐ |
| `get_node("LoginButton").web_auth_code("...")` | 中 | ⭐⭐ |
| `get_node("LoginButton").input_auth_code("...")` | 长 | ⭐ |

## 🐛 常见问题

### 问题：找不到LoginButton
**解决：** 确保当前场景中有LoginButton节点，或使用：
```gdscript
get_tree().get_first_node_in_group("login_button").auth("授权码")
```

### 问题：授权码复制错误
**解决：** 确保授权码以"4/"开头，没有多余空格

### 问题：命令执行没反应
**解决：** 检查授权码是否完整，重新复制

## 🔧 调试命令

### 检查登录状态
```gdscript
print(get_node("LoginButton").signed_in)
```

### 检查用户信息
```gdscript
print(get_node("LoginButton").oauth_manager.get_user_info_dict())
```

### 清除登录状态
```gdscript
get_node("LoginButton").oauth_manager.clear_tokens()
```

## ✨ 成功标志

执行命令后，你会看到：
```
Web平台：手动输入授权码 - 4/0AVMBsJh1hHwMJA-QGA0...
正在处理授权码...
```

然后登录按钮会显示你的用户名，表示登录成功！

## 📝 总结

整个流程只需要 **一次复制粘贴操作**：
1. 点击登录 → 自动跳转
2. Google授权 → 自动回调  
3. **复制命令** → 粘贴执行 ← 唯一的手动步骤
4. 完成登录 → 显示用户名

这是一个简单、可靠的Web OAuth解决方案！ 