extends Resource
class_name NetworkConfig

# 网络配置常量  
const DEFAULT_PORT = 9528
const DEFAULT_IP = "127.0.0.1"

# 平台检测
static func get_platform_type() -> String:
	if OS.has_feature("dedicated_server"):
		return "dedicated_server"
	elif OS.has_feature("mobile"):
		return "mobile"
	else:
		return "desktop"

# 获取推荐的多人游戏peer类型
static func get_recommended_peer_type() -> String:
	return "enet"  # 所有平台使用ENet

# 打印网络配置信息
static func print_network_info():
	var platform = get_platform_type()
	var recommended_peer = get_recommended_peer_type()
	
	print("=== 网络配置信息 ===")
	print("平台类型: %s" % platform)
	print("连接类型: %s" % recommended_peer)
	print("===================") 