extends Node

# 从字节创建纹理
func texture_from_bytes(image_data: PackedByteArray) -> Texture2D:
	var image = Image.new()
	
	# 尝试PNG格式
	if image.load_png_from_buffer(image_data) == OK:
		#print("成功加载PNG图像")
		return ImageTexture.create_from_image(image)
	
	# 尝试JPG格式
	if image.load_jpg_from_buffer(image_data) == OK:
		#print("成功加载JPG图像")
		return ImageTexture.create_from_image(image)
	
	# 尝试WEBP格式
	if image.load_webp_from_buffer(image_data) == OK:
		#print("成功加载WEBP图像")
		return ImageTexture.create_from_image(image)
	
	push_error("无法解码图像数据")
	return null
