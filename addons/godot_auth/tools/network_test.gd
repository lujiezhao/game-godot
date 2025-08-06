extends Node

# 网络测试脚本
# 用于验证混合网络架构是否正常工作

func _ready():
	print("=== 网络架构测试 ===")
	test_platform_detection()
	test_peer_recommendation()
	print("=====================")

func test_platform_detection():
	print("\n1. 平台检测测试:")
	var platform = NetworkConfig.get_platform_type()
	print("  当前平台: %s" % platform)
	
	# 测试平台特征
	print("  平台特征:")
	print("    - dedicated_server: %s" % OS.has_feature("dedicated_server"))
	print("    - mobile: %s" % OS.has_feature("mobile"))
	print("    - debug: %s" % OS.has_feature("debug"))

func test_peer_recommendation():
	print("\n2. 网络连接测试:")
	var recommended = NetworkConfig.get_recommended_peer_type()
	print("  连接类型: %s" % recommended)

# 可以在游戏中调用此函数进行快速测试
static func run_quick_test():
	var tester = preload("res://addons/godot_auth/tools/network_test.gd").new()
	tester._ready()
	tester.queue_free() 