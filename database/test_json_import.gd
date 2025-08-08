extends RefCounted

# 简单测试JSONImporter是否可以正常解析
func test_json_importer():
	print("测试JSONImporter类...")
	
	# 测试格式检测
	var test_data = {
		"game_info": {
			"name": "测试游戏"
		}
	}
	
	var detected_format = JSONImporter.detect_data_format(test_data)
	print("检测到格式: " + detected_format)
	
	if detected_format == "EXPORT_FORMAT":
		print("✅ JSONImporter类解析正常")
		return true
	else:
		print("❌ JSONImporter类解析异常")
		return false 