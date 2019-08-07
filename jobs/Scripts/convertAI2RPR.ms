
/*

	Arnold to RadeonProRender Converter

	History:
	v.1.0 - first release
	
	Supported materials:
	- 

	Supported utilities:
	- 

	Supported lights:
	- 

*/

orig_mtls=#()
new_mtls=#()
orig_lights=#()
new_lights=#()

unsupportedPostfixStr = "_unsupported"
rprPostfixStr = "_rpr"

log_file = maxFilePath + maxFileName + ".log"

fn write_own_property_log msg =(
	try (
		log_obj = openFile log_file mode: "a"
		format "%\r\n" (msg as string) to: log_obj
		flush log_obj
		close log_obj
		free log_obj
	) catch ()
)

-- conv = converting
fn write_converted_property_log rpr_obj conv_obj rpr_attr conv_attr =(
	try (
		log_obj = openFile log_file mode: "a"
		msg = StringStream ""
		format "\tProperty %.% is converted to %.%" (conv_obj as string) conv_attr (rpr_obj as string) rpr_attr to: msg
		format "%\r\n" (msg as string) to: log_obj
		flush log_obj
		close log_obj
		free log_obj
	) catch (
		print("Exception:" + getCurrentException())
		print("Stack trace: " + getCurrentExceptionStackTrace())
	)
)

fn startConversion =(
	msg = "START CONVERSION.\r\n"
	msg += "Start time: " + (localtime as string) + "\r\n"

	try (
		log_obj = openFile log_file mode: "w"
		format "%" (msg as string) to: log_obj
		flush log_obj
		close log_obj
		free log_obj
	) catch ()

)

fn finishConversion time =(
	msg = "\n\nCONVERSION IS FINISHED.\r\n"
	msg += "Total time: " + (time as string) + " seconds.\r\n"

	write_own_property_log msg
)

fn start_log conv_obj rpr_obj =(
	msg = "\n\nFound node:\r\n"
	msg += "\tname: " + (conv_obj as string) + "\r\n"
	msg += "\ttype: " + classof conv_obj as string + "\r\n"
	msg += "Converting to:\r\n" 
    msg += "\tname: " + (rpr_obj as string) + "\r\n"
    msg += "\ttype: " + classof rpr_obj as string + "\r\n"
    msg += "Conversion details:"

	write_own_property_log msg
)

fn end_log conv_obj =(
	msg = StringStream ""
	format "Conversion of % is finished. \r\n" (conv_obj as string) to: msg
	write_own_property_log msg
)


fn convertMaterial orig_mtl =()


fn get_property value_mat value_attr =(
	try (
		obj_value = getProperty value_mat value_attr
		return obj_value
	) catch (
		print("Exception:" + getCurrentException())
		print("Stack trace: " + getCurrentExceptionStackTrace())
		msg = StringStream ""
		format "[ERROR] There is no %.% field in this node. Check the field and try again." (value_mat as string) value_attr to: msg
		write_own_property_log msg
	)
)

fn set_property obj obj_property value =(
	try (
		msg = StringStream ""
		setProperty obj obj_property value
		format "\tSet value % to %.%" value (obj as string) obj_property to: msg
		write_own_property_log msg
	) catch (
		print("Exception:" + getCurrentException())
		print("Stack trace: " + getCurrentExceptionStackTrace())
		format "\t[ERROR] Set value % to %.% is failed. Check the values and their boundaries." value (obj as string) obj_property to: msg
		write_own_property_log msg
	)
)

fn copy_property rpr_mat conv_mat rpr_attr conv_attr =(
	try (
		rpr_value = get_property rpr_mat rpr_attr
		conv_value = get_property conv_mat conv_attr
		if classof rpr_value == UndefinedClass then (
			convObj = convertMaterial conv_value
			set_property rpr_mat rpr_attr convObj
		) else (
			set_property rpr_mat rpr_attr conv_value
		)
		write_converted_property_log rpr_mat conv_mat rpr_attr conv_attr
	) catch (
		print("Exception:" + getCurrentException())
		print("Stack trace: " + getCurrentExceptionStackTrace())
		msg = StringStream ""
		format "[ERROR] Error while converting from %.% to %.%" (conv_mat as string) conv_attr (rpr_mat as string) rpr_attr to: msg
		write_own_property_log msg
	)
)

fn errorCatching functionName orig =(
	errcls = classof orig
	try(
		out = functionName orig
	)catch(
		print ("Error occured in " + errcls as string + " : " + orig as string + "\r\n" + getCurrentException() ) 
		print ("Stack trace: " + getCurrentExceptionStackTrace())
		out = orig
	)
	out
)

fn remap_value currentValue maxInput minInput maxOutput minOutput =(

	if currentValue > maxInput do currentValue = maxInput
	if currentValue < minInput do currentValue = minInput

	inputDiff = maxInput - minInput
	outputDiff = maxOutput - minOutput

	remapped_value = minOutput + (((currentValue - minInput) as float / (inputDiff) as float) * outputDiff)

	remapped_value
)

fn convertTemperature temperature =(
	temperature = temperature / 100

	if temperature <= 66 then (
		colorR = 255
	) else (
		colorR = temperature - 60
		colorR = 329.698727446 * colorR ^ -0.1332047592
		if colorR < 0 do colorR = 0
		if colorR > 255 do colorR = 255
	)

	if temperature <= 66 then (
		colorG = temperature
		colorG = 99.4708025861 * log colorG - 161.1195681661
		if colorG < 0 do colorG = 0
		if colorG > 255 do colorG = 255
	) else (
		colorG = temperature - 60
		colorG = 288.1221695283 * colorG ^ -0.0755148492
		if colorG < 0 do colorG = 0
		if colorG > 255 do colorG = 255
	)

	if temperature >= 66 then (
		colorB = 255
	) else if temperature <= 19 then (
		colorB = 0
	) else (
		colorB = temperature - 10
		colorB = 138.5177312231 * log colorB - 305.0447927307
		if colorB < 0 do colorB = 0
		if colorB > 255 do colorB = 255
	)

	(color colorR colorG colorB)
)

fn invertMap rpr_obj orig_obj rpr_map orig_map =(
	if get_property orig_obj orig_map != undefined do (
		arith = RPR_Arithmetic()
		set_property arith "operator" 1
		set_property arith "Color1" (color 255 255 255)
		copy_property arith orig_obj "color1texmap" orig_map
		set_property rpr_obj rpr_map arith
	)
)

fn getBBoxPoints obj = (
	local bbPoints = #()

	local bbMax = obj.max
	local bbMin = obj.min

	append bbPoints (Point3 bbMax.x bbMax.y bbMax.z)	-- top-right-front corner
	append bbPoints (Point3 bbMax.x bbMin.y bbMax.z)	-- top-right-back corner
	append bbPoints (Point3 bbMin.x bbMin.y bbMax.z)	-- top-left-back corner
	append bbPoints (Point3 bbMin.x bbMax.y bbMax.z)	-- top-left-front corner
	
	append bbPoints (Point3 bbMax.x bbMax.y bbMin.z)	-- bottom-right-front corner
	append bbPoints (Point3 bbMax.x bbMin.y bbMin.z)	-- bottom-right-back corner
	append bbPoints (Point3 bbMin.x bbMin.y bbMin.z)	-- bottom-left-back corner
	append bbPoints (Point3 bbMin.x bbMax.y bbMin.z)	-- bottom-left-front corner
	
	return bbPoints
)


fn convertTemperature temperature =(
	temperature = temperature / 100

	if temperature <= 66 then (
		colorR = 255
	) else (
		colorR = temperature - 60
		colorR = 329.698727446 * colorR ^ -0.1332047592
		if colorR < 0 do colorR = 0
		if colorR > 255 do colorR = 255
	)

	if temperature <= 66 then (
		colorG = temperature
		colorG = 99.4708025861 * log colorG - 161.1195681661
		if colorG < 0 do colorG = 0
		if colorG > 255 do colorG = 255
	) else (
		colorG = temperature - 60
		colorG = 288.1221695283 * colorG ^ -0.0755148492
		if colorG < 0 do colorG = 0
		if colorG > 255 do colorG = 255
	)

	if temperature >= 66 then (
		colorB = 255
	) else if temperature <= 19 then (
		colorB = 0
	) else (
		colorB = temperature - 10
		colorB = 138.5177312231 * log colorB - 305.0447927307
		if colorB < 0 do colorB = 0
		if colorB > 255 do colorB = 255
	)

	(color colorR colorG colorB)
)


/* 
    MATERIALS
*/


fn convertUnsupportedMtl origMtl =(
	local r = RPR_Uber_Material()
	r.name = origMtl.name + unsupportedPostfixStr

	-- log to file 
	start_log origMtl r

	set_property r "diffuseColor" (color 0 45 0)

	-- logging
	end_log origMtl

	r
)

fn convertMultimaterial origMtl =(

	-- log to file 
	start_log origMtl origMtl

	materialList = get_property origMtl "materialList"
	for m=1 to materialList.count do (
		materialList[m] = convertMaterial materialList[m]
	)
	set_property origMtl "materialList" materialList

	-- logging
	end_log origMtl

	origMtl
)


fn convertAiStandardSurface origMtl =(
	local r = RPR_Uber_Material()
	r.name = origMtl.name + rprPostfixStr

	-- log to file 
	start_log origMtl r

	-- diffuse
	if get_property origMtl "base" > 0 or get_property origMtl "base_shader" != undefined do (set_property r "DiffuseEnable" true)
	copy_property r origMtl "DiffuseColor" "base_color"
	copy_property r origMtl "DiffuseColorTexmap" "base_color_shader"
	copy_property r origMtl "DiffuseWeight" "base"
	copy_property r origMtl "DiffuseWeightTexmap" "base_shader"
	copy_property r origMtl "DiffuseRoughness" "diffuse_roughness"
	copy_property r origMtl "DiffuseRoughnessTexmap" "diffuse_roughness_shader"

	copy_property r origMtl "RefractionAllowCaustics" "caustics"
	
	-- reflection
	if get_property origMtl "specular" > 0 or get_property origMtl "specular_shader" != undefined do (set_property r "reflectionEnable" true)
	copy_property r origMtl "reflectionColor" "specular_color"
	copy_property r origMtl "reflectionColorTexmap" "specular_color_shader"
	copy_property r origMtl "reflectionWeight" "specular"
	copy_property r origMtl "ReflectionWeightTexmap" "specular_shader"
	copy_property r origMtl "reflectionRoughness" "specular_roughness"
	copy_property r origMtl "reflectionRoughnessTexmap" "specular_roughness_shader"

	if get_property origMtl "metalness" > 0 or get_property origMtl "metalness_shader" != undefined do (
		set_property r "DiffuseEnable" true
		set_property r "reflectionEnable" true
		set_property r "reflectionMode" 2
		copy_property r origMtl "reflectionColor" "base_color"
		copy_property r origMtl "reflectionColorTexmap" "base_color_shader"
	)

	copy_property r origMtl "reflectionIor" "specular_IOR"
	copy_property r origMtl "reflectionIorTexmap" "specular_IOR_shader"
	copy_property r origMtl "reflectionMetalness" "metalness"
	copy_property r origMtl "reflectionMetalnessTexmap" "metalness_shader"

	copy_property r origMtl "reflectionAnisotropy" "specular_anisotropy"
	copy_property r origMtl "reflectionAnisotropyTexmap" "specular_anisotropy_shader"
	copy_property r origMtl "reflectionAnisotropyRotation" "specular_rotation"
	copy_property r origMtl "reflectionAnisotropyRotationTexmap" "specular_rotation_shader"

	-- refraction
	if get_property origMtl "transmission" > 0 or get_property origMtl "transmission_shader" != undefined do (set_property r "refractionEnable" true)
	copy_property r origMtl "RefractionWeight" "transmission"
	copy_property r origMtl "RefractionWeightTexmap" "transmission_shader"
	copy_property r origMtl "RefractionColor" "transmission_color"
	copy_property r origMtl "RefractionColorTexmap" "transmission_color_shader"

	copy_property r origMtl "RefractionThinSurface" "thin_walled"
	copy_property r origMtl "RefractionIor" "specular_IOR"
	copy_property r origMtl "RefractionIorTexmap" "specular_IOR_shader"

	copy_property r origMtl "RefractionAbsorptionDistance" "transmission_depth"

	-- subsurface
	if get_property origMtl "subsurface" > 0 or get_property origMtl "subsurface_shader" != undefined do (
		set_property r "DiffuseEnable" true
		set_property r "DiffuseWeight" 1
		set_property r "DiffuseBackscatteringWeight" 0.75
		set_property r "SssEnable" true
		copy_property r origMtl "DiffuseBackScatteringColor" "subsurface_color"
		copy_property r origMtl "DiffuseBackScatteringColorTexmap" "subsurface_color_shader"
	)

	copy_property r origMtl "SssWeight" "subsurface"
	copy_property r origMtl "SssWeightTexmap" "subsurface_shader"
	copy_property r origMtl "SssColor" "subsurface_color"
	copy_property r origMtl "SssColorTexmap" "subsurface_color_shader"
	copy_property r origMtl "SssRadius" "subsurface_radius"
	copy_property r origMtl "SssRadiusTexmap" "subsurface_radius_shader"

	-- coat
	if get_property origMtl "coat" > 0 or get_property origMtl "coat_shader" != undefined do (set_property r "CoatingEnable" true)
	copy_property r origMtl "CoatingWeight" "coat"
	copy_property r origMtl "CoatingWeightTexmap" "coat_shader"

	if get_property origMtl "coat_color" == (color 255 255 255) and get_property origMtl "coat_shader" == undefined then (
		copy_property r origMtl "CoatingColor" "coat_color"
		copy_property r origMtl "CoatingColorTexmap" "coat_color_shader"
	) else if get_property origMtl "coat_shader" == undefined then (
		set_property r "CoatingColor" (color 255 255 255)
		arith = RPR_Arithmetic()
		set_property arith "operator" 2
		copy_property arith origMtl "Color1" "base_color"
		copy_property arith origMtl "color0texmap" "base_color_shader"
		copy_property arith origMtl "Color2" "coat_color"
		copy_property arith origMtl "color1texmap" "coat_color_shader"
		set_property r "diffuseColorTexmap" arith
	) else (
		set_property r "CoatingColor" (color 255 255 255)
		blend_value = RPR_Blend_Value()
		copy_property blend_value origMtl "Color1" "base_color"
		copy_property blend_value origMtl "color0Texmap" "base_color_shader"

		arith = RPR_Arithmetic()
		set_property arith "operator" 2
		copy_property arith origMtl "Color1" "base_color"
		copy_property arith origMtl "color0texmap" "base_color_shader"
		copy_property arith origMtl "Color2" "coat_color"
		copy_property arith origMtl "color1texmap" "coat_color_shader"
		
		set_property blend_value "color1Texmap" arith
		copy_property blend_value origMtl "weightTexmap" "coat_shader"
		set_property r "diffuseColorTexmap" blend_value
	)

	copy_property r origMtl "CoatingRoughness" "coat_roughness"
	copy_property r origMtl "CoatingRoughnessTexmap" "coat_roughness_shader"
	copy_property r origMtl "CoatingIor" "coat_IOR"
	copy_property r origMtl "CoatingIorTexmap" "coat_IOR_shader"
	if (get_property origMtl "coat_normal_shader") != undefined do (
		set_property r "CoatingUseShaderNormal" false
		copy_property r origMtl "CoatingNormalTexmap" "coat_normal_shader"
	)
	set_property r "CoatingThickness" 1.5

	-- emission
	if get_property origMtl "emission" > 0 or get_property origMtl "emission_color_shader" != undefined do (set_property r "emissiveEnable" true)
	set_property r "EmissiveWeight" 0.35
	copy_property r origMtl "EmissiveColor" "emission_color"
	copy_property r origMtl "EmissiveColorTexmap" "emission_color_shader"
	set_property r "EmissiveIntensity" ((get_property origMtl "emission") *2.5)

	if get_property origMtl "opacity" != (color 255 255 255) then (
		set_property r "TransparencyEnable" true
		original_opacity_color = get_property origMtl "opacity"
		opacity_color = amax #(original_opacity_color.red, original_opacity_color.green, original_opacity_color.blue)
		set_property r "Transparency" opacity_color
	)

	if get_property origMtl "opacity_shader" != undefined do (
		set_property r "TransparencyEnable" true
		arith = RPR_Arithmetic()
		set_property arith "operator" 1
		set_property arith "Color1" (color 255 255 255)
		copy_property arith origMtl "color1texmap" "opacity_shader"
		set_property r "transparencyTexmap" arith
	)

	if get_property origMtl "normal_shader" != undefined do (
		set_property r "CoatingUseShaderNormal" false
		set_property r "normalEnable" true
		copy_property r origMtl "normalTexmap" "normal_shader"
	)

	-- logging
	end_log origMtl

	r
)

fn convertAiCarPaint origMtl =(
	local r = RPR_Uber_Material()
	r.name = origMtl.name + rprPostfixStr

	-- log to file 
	start_log origMtl r

	-- diffuse
	if get_property origMtl "base" > 0 or get_property origMtl "base_shader" != undefined do (set_property r "DiffuseEnable" true)
	copy_property r origMtl "DiffuseColor" "base_color"
	copy_property r origMtl "DiffuseColorTexmap" "base_color_shader"
	copy_property r origMtl "DiffuseWeight" "base"
	copy_property r origMtl "DiffuseWeightTexmap" "base_shader"
	copy_property r origMtl "DiffuseRoughness" "base_roughness"
	copy_property r origMtl "DiffuseRoughnessTexmap" "base_roughness_shader"
	
	-- reflection
	if get_property origMtl "specular" > 0 or get_property origMtl "specular_shader" != undefined do (set_property r "reflectionEnable" true)
	copy_property r origMtl "reflectionColor" "specular_color"
	copy_property r origMtl "reflectionColorTexmap" "specular_color_shader"
	copy_property r origMtl "reflectionWeight" "specular"
	copy_property r origMtl "ReflectionWeightTexmap" "specular_shader"
	copy_property r origMtl "reflectionRoughness" "specular_roughness"
	copy_property r origMtl "reflectionRoughnessTexmap" "specular_roughness_shader"
	copy_property r origMtl "reflectionIor" "specular_IOR"
	copy_property r origMtl "reflectionIorTexmap" "specular_IOR_shader"

	-- coat
	if get_property origMtl "coat" > 0 or get_property origMtl "coat_shader" != undefined do (set_property r "CoatingEnable" true)
	copy_property r origMtl "CoatingWeight" "coat"
	copy_property r origMtl "CoatingWeightTexmap" "coat_shader"

	if get_property origMtl "coat_color" == (color 255 255 255) and get_property origMtl "coat_shader" == undefined then (
		copy_property r origMtl "CoatingColor" "coat_color"
		copy_property r origMtl "CoatingColorTexmap" "coat_color_shader"
	) else if get_property origMtl "coat_shader" == undefined then (
		set_property r "CoatingColor" (color 255 255 255)
		arith = RPR_Arithmetic()
		set_property arith "operator" 2
		copy_property arith origMtl "Color1" "base_color"
		copy_property arith origMtl "color0texmap" "base_color_shader"
		copy_property arith origMtl "Color2" "coat_color"
		copy_property arith origMtl "color1texmap" "coat_color_shader"
		set_property r "diffuseColorTexmap" arith
	) else (
		set_property r "CoatingColor" (color 255 255 255)
		blend_value = RPR_Blend_Value()
		copy_property blend_value origMtl "Color1" "base_color"
		copy_property blend_value origMtl "color0Texmap" "base_color_shader"

		arith = RPR_Arithmetic()
		set_property arith "operator" 2
		copy_property arith origMtl "Color1" "base_color"
		copy_property arith origMtl "color0texmap" "base_color_shader"
		copy_property arith origMtl "Color2" "coat_color"
		copy_property arith origMtl "color1texmap" "coat_color_shader"
		
		set_property blend_value "color1Texmap" arith
		copy_property blend_value origMtl "weightTexmap" "coat_shader"
		set_property r "diffuseColorTexmap" blend_value
	)

	copy_property r origMtl "CoatingRoughness" "coat_roughness"
	copy_property r origMtl "CoatingRoughnessTexmap" "coat_roughness_shader"
	copy_property r origMtl "CoatingIor" "coat_IOR"
	copy_property r origMtl "CoatingIorTexmap" "coat_IOR_shader"

	if get_property origMtl "coat_normal_shader" != undefined do (
		set_property r "normalEnable" true
		copy_property r origMtl "normalTexmap" "coat_normal_shader"
	)

	-- logging
	end_log origMtl

	r
)

fn convertAiLayerShader origMtl =(
	local r = RPR_Blend_Material()
	r.name = origMtl.name + rprPostfixStr

	-- log to file 
	start_log origMtl r

	first_material = true
	second_material = true
	for i=1 to 8 do (
		if get_property origMtl ("enable" + i as string) do (
			input = get_property origMtl ("input" + i as string)
			if input != undefined do (
				if first_material then (
					copy_property r origMtl "material1" ("input" + i as string)
					first_material = false
				) else if second_material then (
					copy_property r origMtl "material2" ("input" + i as string)
					copy_property r origMtl "weight" ("mix" + i as string)
					copy_property r origMtl "weightMap" ("mix" + i as string + "_shader")
					second_material = false
				) else (
					old_r = r
					r = RPR_Blend_Material()
					set_property r "material1" old_r
					copy_property r origMtl "material2" ("input" + i as string)
					copy_property r origMtl "weight" ("mix" + i as string)
					copy_property r origMtl "weightMap" ("mix" + i as string + "_shader")
				)
			)
		)
	)
	
	-- logging
	end_log origMtl

	r
)

fn convertAiMixShader origMtl =(
	local r = RPR_Blend_Material()
	r.name = origMtl.name + rprPostfixStr

	-- log to file 
	start_log origMtl r

	copy_property r origMtl "material1" "shader1"
	copy_property r origMtl "material2" "shader2"
	copy_property r origMtl "weight" "mix"
	copy_property r origMtl "weightMap" "mix_shader"
	
	-- logging
	end_log origMtl

	r
)

fn convertAiShadowMatte origMtl =(
	local r = rpr_shadow_catcher_material()
	r.name = origMtl.name + rprPostfixStr

	-- log to file 
	start_log origMtl r

	set_property r "BackgroundTrancparencyMul" 0

	if get_property origMtl "background" then (
		set_property r "BackgroundIsEnvironment" false
		copy_property r origMtl "BackgroundColor" "background_color"
		copy_property r origMtl "BackgroundColorTexmap" "background_color_shader"
	) else (
		set_property r "BackgroundIsEnvironment" true
		domeLight = for o in objects where superclassof o == light and get_property o "category" == #Arnold and get_property o "shapeType" == 6 collect o
		if domeLight.count > 0 and get_property domeLight[1] "texmap" != undefined then (
			background_map = get_property domeLight[1] "texmap"
		) else (
			background_map = environmentMap
		)
		set_property r "BackgroundColorTexmap" background_map

	)

	copy_property r origMtl "ShadowColor" "shadow_color"
	copy_property r origMtl "ShadowColorTexmap" "shadow_color_shader"
	set_property r "ShadowAlphaMul" (1 - get_property origMtl "shadow_opacity")
	
	-- logging
	end_log origMtl

	r
)


fn convertAiBlackbody origMtl =(
	local r = rpr_emissive_material()

	r.name = origMtl.name + rprPostfixStr

	-- log to file 
	start_log origMtl r

	set_property r "IntMode" 0
	set_property r "ColorMode" 1
	copy_property r origMtl "Kelvin" "temperature"

	-- logging
	end_log origMtl

	r
)

fn convertAiToon origMtl = (
	local r = RPR_Uber_Material()
	r.name = origMtl.name + rprPostfixStr

	-- log to file 
	start_log origMtl r

	-- diffuse
	if get_property origMtl "base" > 0 or get_property origMtl "base_shader" != undefined do (set_property r "DiffuseEnable" true)
	copy_property r origMtl "DiffuseWeight" "base"
	copy_property r origMtl "DiffuseWeightTexmap" "base_shader"
	copy_property r origMtl "DiffuseColor" "base_color"
	copy_property r origMtl "DiffuseColorTexmap" "base_color_shader"

	-- reflection 
	if get_property origMtl "specular" > 0 or get_property origMtl "specular_shader" != undefined do (set_property r "ReflectionEnable" true)
	copy_property r origMtl "ReflectionWeight" "specular"
	copy_property r origMtl "ReflectionWeightTexmap" "specular_shader"
	copy_property r origMtl "ReflectionColor" "specular_color"
	copy_property r origMtl "ReflectionColorTexmap" "specular_color_shader"
	copy_property r origMtl "ReflectionRoughness" "specular_roughness"
	copy_property r origMtl "ReflectionRoughnessTexmap" "specular_roughness_shader"
	copy_property r origMtl "ReflectionAnisotropy" "specular_anisotropy"
	copy_property r origMtl "ReflectionAnisotropyTexmap" "specular_anisotropy_shader"
	copy_property r origMtl "ReflectionAnisotropyRotation" "specular_rotation"
	copy_property r origMtl "ReflectionAnisotropyRotationTexmap" "specular_rotation_shader"

	-- refraction 
	if get_property origMtl "transmission" > 0 or get_property origMtl "transmission_shader" != undefined do (set_property r "RefractionEnable" true)
	copy_property r origMtl "RefractionWeight" "transmission"
	copy_property r origMtl "RefractionWeightTexmap" "transmission_shader"
	copy_property r origMtl "RefractionColor" "transmission_color"
	copy_property r origMtl "RefractionColorTexmap" "transmission_color_shader"
	copy_property r origMtl "RefractionRoughness" "transmission_roughness"
	copy_property r origMtl "RefractionRoughnessTexmap" "transmission_roughness_shader"
	copy_property r origMtl "RefractionIor" "IOR"
	copy_property r origMtl "RefractionIorTexmap" "IOR_shader"

	-- emission 
	if get_property origMtl "emission" > 0 or get_property origMtl "emission_shader" != undefined do (set_property r "EmissiveEnable" true)
	copy_property r origMtl "EmissiveWeight" "emission"
	copy_property r origMtl "EmissiveWeightTexmap" "emission_shader"
	copy_property r origMtl "EmissiveColor" "emission_color"
	copy_property r origMtl "EmissiveColorTexmap" "emission_color_shader"

	-- normal 
	if get_property origMtl "normal_shader" != undefined do (
		set_property r "NormalEnable" true
		copy_property r origMtl "NormalTexmap" "normal_shader"
	)

	-- logging
	end_log origMtl

	r
)

fn convertArnoldMapToMtl origMtl =(

	local mtl = get_property origMtl "SurfaceShader"
	local newMtl = convertMaterial mtl

	newMtl
)

/* 
    UTILITIES
*/

fn convertUnsupportedUtility origMap =(
	local r = RPR_Arithmetic()
	r.name = origMap.name + unsupportedPostfixStr

	-- log to file 
	start_log origMap r
	end_log origMap

	r
)

fn convertColorOSL origMap operator = (
	local r = RPR_Arithmetic()
	r.name = origMap.name + rprPostfixStr

	-- log to file 
	start_log origMap r

	set_property r "operator" operator
	copy_property r origMap "Color1" "A"
	copy_property r origMap "Color2" "B"
	copy_property r origMap "color0texmap" "A_map"
	copy_property r origMap "color1texmap" "B_map"
	
	-- logging
	end_log origMap

	r
)

fn convertColorClampOSL origMap = (
	local r = RPR_Arithmetic()
	r.name = origMap.name + rprPostfixStr

	-- log to file 
	start_log origMap r

	set_property r "operator" 12

	arith = RPR_Arithmetic()
	set_property arith "operator" 13
	copy_property arith origMap "Color1" "Input"
	copy_property arith origMap "Color2" "min"
	copy_property arith origMap "color0texmap" "Input_map"
	copy_property arith origMap "color1texmap" "Min_map"
	
	set_property r "color0texmap" arith
	copy_property r origMap "Color2" "max"
	copy_property r origMap "color1texmap" "Max_map"

	-- logging
	end_log origMap

	r
)

fn convertColorCompOSL origMap = (
	local r = RPR_Arithmetic()
	r.name = origMap.name + rprPostfixStr

	-- log to file 
	start_log origMap r

	set_property r "operator" 1
	set_property r "Color1" (color 255 255 255)
	copy_property r origMap "Color2" "input"
	copy_property r origMap "color1texmap" "input_map"

	-- logging
	end_log origMap

	r
)

fn convertOSLMap origMap = (

	OSLPath = get_property origMap "OSLPath"
	OSLFile = (filterString OSLPath "\\")
	OSLFile = OSLFile[OSLFile.count]
	local new_osl = case OSLFile of (
		"ColorAdd.osl": convertColorOSL origMap 0
		"ColorSub.osl": convertColorOSL origMap 1
		"ColorMul.osl": convertColorOSL origMap 2
		"ColorDiv.osl": convertColorOSL origMap 3
		"ColorMin.osl": convertColorOSL origMap 12
		"ColorMax.osl": convertColorOSL origMap 13
		"ColorClamp.osl": convertColorClampOSL origMap
		"ColorComp.osl": convertColorCompOSL origMap

		default: origMap
	)

	new_osl
	
)

fn convertMathUtility origMap =(
	local r = RPR_Arithmetic()
	r.name = origMap.name + rprPostfixStr

	-- log to file 
	start_log origMap r

	cls=classof origMap
	local operator=case cls of (
		ai_add: 0
		ai_subtract: 1
		ai_multiply: 2
		ai_divide: 3
		ai_max: 13
		ai_min: 12
		ai_cross: 22
		ai_dot: 10
		
		default: 0
	)

	set_property r "operator" operator
	copy_property r origMap "Color1" "input1"
	copy_property r origMap "Color2" "input2"
	copy_property r origMap "color0texmap" "input1_shader"
	copy_property r origMap "color1texmap" "input2_shader"

	-- logging
	end_log origMap

	r
)

fn convertMathUtilityOneChannel origMap =(
	local r = RPR_Arithmetic()
	r.name = origMap.name + rprPostfixStr

	-- log to file 
	start_log origMap r

	cls=classof origMap
	local operator=case cls of (
		ai_abs: 17
		ai_normalize: 16
		
		default: 0
	)

	set_property r "operator" operator
	copy_property r origMap "Color1" "input"
	copy_property r origMap "color0texmap" "input_shader"

	-- logging
	end_log origMap

	r
)

fn convertAiAtan origMap =(
	local r = RPR_Arithmetic()
	r.name = origMap.name + rprPostfixStr

	-- log to file 
	start_log origMap r

	set_property r "operator" 21
	copy_property r origMap "Color1" "x"
	copy_property r origMap "color0texmap" "x_shader"
	copy_property r origMap "Color2" "y"
	copy_property r origMap "color1texmap" "y_shader"

	-- logging
	end_log origMap

	r
)

fn convertAiModulo origMap =(
	local r = RPR_Arithmetic()
	r.name = origMap.name + rprPostfixStr

	-- log to file 
	start_log origMap r

	set_property r "operator" 18
	copy_property r origMap "Color1" "input"
	copy_property r origMap "color0texmap" "input_shader"
	copy_property r origMap "Color2" "divisor"
	copy_property r origMap "color1texmap" "divisor_shader"

	-- logging
	end_log origMap

	r
)

fn convertAiPow origMap =(
	local r = RPR_Arithmetic()
	r.name = origMap.name + rprPostfixStr

	-- log to file 
	start_log origMap r

	set_property r "operator" 11
	copy_property r origMap "Color1" "base"
	copy_property r origMap "color0texmap" "base_shader"
	copy_property r origMap "Color2" "exponent"
	copy_property r origMap "color1texmap" "exponent_shader"

	-- logging
	end_log origMap

	r
)

fn convertAiSqrt origMap =(
	local r = RPR_Arithmetic()
	r.name = origMap.name + rprPostfixStr

	-- log to file 
	start_log origMap r

	set_property r "operator" 11
	copy_property r origMap "Color1" "input"
	copy_property r origMap "color0texmap" "input_shader"
	set_property r "Color2" (color 128 128 128)

	-- logging
	end_log origMap

	r
)

fn convertAiExp origMap =(
	local r = rpr_color_value()
	r.name = origMap.name + rprPostfixStr

	-- log to file 
	start_log origMap r

	input_color = get_property origMap "input"
	base_color = #(remap_value input_color.red 255 0 1 0, remap_value input_color.green 255 0 1 0, remap_value input_color.blue 255 0 1 0)
	exp_color = #(2.718^base_color[1], 2.718^base_color[2], 2.718^base_color[1])
	for i=1 to exp_color.count do(
		if exp_color[i]>1 then(
			exp_color[i] = 255
		) else (
			exp_color[i] = remap_value exp_color[i] 1 0 255 0
		)
	)

	set_property r "Color" (color exp_color[1] exp_color[2] exp_color[3])

	-- logging
	end_log origMap

	r
)

fn convertAiNormalMap origMap = (
	local r = RPR_Normal()
	r.name = origMap.name + rprPostfixStr
	
	-- log to file 
	start_log origMap r

	if get_property origMap "input_shader" != undefined then (
		copy_property r origMap "map" "input_shader"
	) else (
		copy_property r origMap "map" "normal_shader"
	)

	if get_property origMap "strength" > 1.0 then (
		set_property r "strength" 1.0
	) else (
		copy_property r origMap "strength" "strength"
	)

	-- logging
	end_log origMap

	r
)

fn convertAiBump origMap = (
	local r = RPR_Normal()
	r.name = origMap.name + rprPostfixStr

	-- log to file 
	start_log origMap r
	
	set_property r "isBump" true

	if get_property origMap "bump_map_shader" != undefined then (
		copy_property r origMap "map" "bump_map_shader"
	) else (
		copy_property r origMap "map" "normal_shader"
	)

	if get_property origMap "bump_height" * 100.0 > 1.0 then (
		set_property r "strength" 1.0
	) else (
		set_property r "strength" (get_property origMap "bump_height" * 100.0)
	)

	-- logging
	end_log origMap

	r
)


fn convertAiVectorMap origMap = (
	local r = RPR_Normal()
	r.name = origMap.name + rprPostfixStr
	
	-- log to file 
	start_log origMap r


	if get_property origMap "input_shader" != undefined then (
		copy_property r origMap "map" "input_shader"
	) else (
		copy_property r origMap "map" "normal_shader"
	)

	if get_property origMap "scale" > 1.0 then (
		set_property r "strength" 1.0
	) else (
		copy_property r origMap "strength" "scale"
	)

	-- logging
	end_log origMap

	r
)

fn convertAiAO origMap = (
	local r = Rpr_Ambient_Occlusion()
	r.name = origMap.name + rprPostfixStr

	-- log to file 
	start_log origMap r
	
	set_property r "Radius" (0.0187 * get_property origMap "far_clip" + 0.0467)

	if get_property origMap "invert_normals" then (
		set_property r "Side" 1
	) else (
		set_property r "Side" 0
	)

	copy_property r origMap "Unoccluded_Color" "white"
	copy_property r origMap "Occluded_Color" "black"
	copy_property r origMap "color0Texmap" "white_shader"
	copy_property r origMap "color1Texmap" "black_shader"

	-- logging
	end_log origMap

	r
)


fn convertAiNegate origMap = (
	local r = rpr_arithmetic()
	r.name = origMap.name + rprPostfixStr

	-- log to file 
	start_log origMap r

	set_property r "operator" 1
	set_property r "Color1" (color 255 255 255)
	copy_property r origMap "Color2" "input"
	copy_property r origMap "color1texmap" "input_shader"

	-- logging
	end_log origMap

	r
)

fn convertAiReciprocal origMap = (
	local r = rpr_arithmetic()
	r.name = origMap.name + rprPostfixStr

	-- log to file 
	start_log origMap r

	set_property r "operator" 3
	set_property r "Color1" (color 255 255 255)
	copy_property r origMap "Color2" "input"
	copy_property r origMap "color1texmap" "input_shader"

	-- logging
	end_log origMap

	r
)

fn convertAiSign origMap = (
	local r = rpr_color_value()
	r.name = origMap.name + rprPostfixStr

	-- log to file 
	start_log origMap r

	input_color = get_property origMap "input"
	output_color = color 0 0 0
	if input_color.red > 0 then output_color.red = 255
	if input_color.green > 0 then output_color.green = 255
	if input_color.blue > 0 then output_color.blue = 255
	set_property r "Color" output_color

	-- logging
	end_log origMap

	r
)

fn convertAiTrigo origMap = (
	local r = rpr_arithmetic()
	r.name = origMap.name + rprPostfixStr

	-- log to file 
	start_log origMap r

	input_color = get_property origMap "input"
	frequency = get_property origMap "frequency"
	phase = get_property origMap "phase"
	output_color = point3 (input_color.red * frequency + phase) (input_color.green * frequency + phase) (input_color.blue * frequency + phase)
	set_property r "Color1" output_color
	operation = get_property origMap "function"
	local operator = case operation of (
		0: 5
		1: 4
		2: 6
		3: 19
		4: 20
		5: 21
		6: 0
		7: 0
		8: 0
	)
	set_property r "operator" operator

	-- logging
	end_log origMap

	r
)

fn convertLayerOperations A_color A_map B_color B_map operation =(
	if operation == 10 do ( -- from : (B - A)
		local r = rpr_arithmetic()
		set_property r "operator" 1
		set_property r "Color1" B_color
		set_property r "color0texmap" B_map
		set_property r "Color2" A_color
		set_property r "color1texmap" A_map
		return r
	)
	if operation == 20 do ( -- max(A,B)
		local r = rpr_arithmetic()
		set_property r "operator" 13
		set_property r "Color1" A_color
		set_property r "color0texmap" A_map
		set_property r "Color2" B_color
		set_property r "color1texmap" B_map
		return r
	)
	if operation == 21 do ( -- min(A,B)
		local r = rpr_arithmetic()
		set_property r "operator" 12
		set_property r "Color1" A_color
		set_property r "color0texmap" A_map
		set_property r "Color2" B_color
		set_property r "color1texmap" B_map
		return r
	)
	if operation == 22 do ( -- (A - B)
		local r = rpr_arithmetic()
		set_property r "operator" 1
		set_property r "Color1" A_color
		set_property r "color0texmap" A_map
		set_property r "Color2" B_color
		set_property r "color1texmap" B_map
		return r
	)
	if operation == 28 do ( -- phoenix : min(A,B) - max(A,B) + 1
		local min_arith = rpr_arithmetic()
		set_property min_arith "operator" 12
		set_property min_arith "Color1" A_color
		set_property min_arith "color0texmap" A_map
		set_property min_arith "Color2" B_color
		set_property min_arith "color1texmap" B_map
		local max_arith = rpr_arithmetic()
		set_property max_arith "operator" 13
		set_property max_arith "Color1" A_color
		set_property max_arith "color0texmap" A_map
		set_property max_arith "Color2" B_color
		set_property max_arith "color1texmap" B_map
		local sub_arith = rpr_arithmetic()
		set_property sub_arith "operator" 1
		set_property sub_arith "color0texmap" min_arith
		set_property sub_arith "color1texmap" max_arith
		local add_arith = rpr_arithmetic()
		set_property add_arith "operator" 0
		set_property add_arith "color0texmap" sub_arith
		set_property add_arith "Color2" (color 255 255 255)
		return add_arith
	)
	if operation == 30 do ( -- (A + B)
		local r = rpr_arithmetic()
		set_property r "operator" 0
		set_property r "Color1" A_color
		set_property r "color0texmap" A_map
		set_property r "Color2" B_color
		set_property r "color1texmap" B_map
		return r
	)
	if operation == 35 do ( -- subract : A + B - 1
		local add_arith = rpr_arithmetic()
		set_property add_arith "operator" 0
		set_property add_arith "Color1" A_color
		set_property add_arith "color0texmap" A_map
		set_property add_arith "Color2" B_color
		set_property add_arith "color1texmap" B_map
		local sub_arith = rpr_arithmetic()
		set_property sub_arith "operator" 1
		set_property sub_arith "color0texmap" add_arith
		set_property sub_arith "Color2" (color 255 255 255)
		return sub_arith
	)
)

fn convertAiLayerRGBA origMap = (
	local r = undefined
	A_color = undefined
	A_map = undefined
	B_color = undefined
	B_map = undefined

	first_material = true
	second_material = true
	for i=1 to 8 do (
		if get_property origMap ("enable" + i as string) do (
			if get_property origMap ("input" + i as string) != undefined do (
				if first_material then (
					A_color = get_property origMap ("input" + i as string)
					A_map = get_property origMap ("input" + i as string + "_shader")
					first_material = false
				) else if second_material then (
					B_color = get_property origMap ("input" + i as string)
					B_map = get_property origMap ("input" + i as string + "_shader")
					operation = get_property origMap ("operation" + i as string)
					second_material = false
					
					r = convertLayerOperations A_color A_map B_color B_map operation
					r.name = origMap.name + rprPostfixStr

					-- log to file 
					start_log origMap r

				) else (
					A_color = (color 128 128 128)
					A_map = r
					B_color = get_property origMap ("input" + i as string)
					B_map = get_property origMap ("input" + i as string + "_shader")
					operation = get_property origMap ("operation" + i as string)
					r = convertLayerOperations A_color A_map B_color B_map operation
				)
			)
		)
	)

	-- logging
	end_log origMap

	r
)


fn convertAiVectorToRGB origMap = (

	if get_property origMap "mode" == 1 then (

		local r = rpr_color_value()
		r.name = origMap.name + rprPostfixStr

		-- log to file 
		start_log origMap r

		input_vector = get_property origMap "input"
		vector_length = sqrt (pow input_vector[1] 2 + pow input_vector[2] 2 + pow input_vector[3] 2)
		invert_length = 1 / vector_length
		normalize_vector = point3 (input_vector[1] * invert_length) (input_vector[2] * invert_length) (input_vector[3] * invert_length)
		remap_vector = point3 (remap_value normalize_vector[1] 1 0 255 0) (remap_value normalize_vector[2] 1 0 255 0) (remap_value normalize_vector[3] 1 0 255 0)
		set_property r "Color" remap_vector

		-- logging
		end_log origMap

		r
	) else (
		return convertUnsupportedUtility(origMap)
	)
)

fn convertAiFlat origMap = (
	local r = rpr_color_value()
	r.name = origMap.name + rprPostfixStr

	-- log to file 
	start_log origMap r

	copy_property r origMap "Color" "color"
	copy_property r origMap "colorTexmap" "color_shader"

	-- logging
	end_log origMap

	r
)


fn convertAiMixRGBA origMap = (
	local r = rpr_blend_value()
	r.name = origMap.name + rprPostfixStr

	-- log to file 
	start_log origMap r

	copy_property r origMap "Color1" "input1"
	copy_property r origMap "Color2" "input2"
	copy_property r origMap "color0Texmap" "input1_shader"
	copy_property r origMap "color1Texmap" "input2_shader"
	copy_property r origMap "Weight" "mix"
	copy_property r origMap "weightTexmap" "mix_shader"

	-- logging
	end_log origMap

	r
)

fn convertAiColorCorrect origMap = (
	local r = rpr_blend_value()
	r.name = origMap.name + rprPostfixStr

	-- log to file 
	start_log origMap r

	arith_mult = rpr_arithmetic()
	set_property arith_mult "operator" 2
	copy_property arith_mult origMap "Color1" "input"

	if get_property origMap "input_shader" != undefined do (
		gamma = texture_gamma_correction()
		set_property gamma "UseGammaCorrection" true
		set_property gamma "Boundary" 0
		set_property gamma "UseCustomGamma" false
		copy_property gamma origMap "Min_Height" "gamma"

		if get_property origMap "invert" then (
			arith_invert = rpr_arithmetic()
			set_property arith_invert "operator" 1
			set_property arith_invert "Color1" (color 255 255 255)
			copy_property arith_invert origMap "Color2" "input"
			copy_property arith_invert origMap "color1Texmap" "input_shader"
			set_property gamma "Map" arith_invert
		) else(
			copy_property gamma origMap "Map" "input_shader"
		)

		set_property arith_mult "color0Texmap" gamma

	)

	copy_property arith_mult origMap "Color2" "multiply"
	copy_property arith_mult origMap "color1Texmap" "multiply_shader"
	
	arith_add = rpr_arithmetic()
	set_property arith_add "operator" 0
	set_property arith_add "color0Texmap" arith_mult
	copy_property arith_add origMap "Color2" "add"
	copy_property arith_add origMap "color1Texmap" "add_shader"

	set_property r "color1Texmap" arith_add
	copy_property r origMap "color0Texmap" "input_shader"
	copy_property r origMap "Weight" "mask"
	copy_property r origMap "weightTexmap" "mask_shader"

	-- logging
	end_log origMap

	r
)

/* 
    LIGHTS
*/

fn convertIesLight origLight = (
	local r = ies_light()
	r.name = origLight.name + rprPostfixStr

	-- log to file 
	start_log origLight r

	-- On/Off, Include/exclude
	copy_property r origLight "enabled" "on"
	copy_property r origLight "targeted" "targeted"

	-- position conversion
	set_property origLight "targeted" false
	copy_property r origLight "pos" "pos"
	copy_property r origLight "rotation" "rotation"
	copy_property r origLight "scale" "scale"
	copy_property r origLight "pivot" "pivot"
	copy_property r origLight "transform" "transform"
	copy_property r origLight "dir" "dir"
	copy_property r origLight "ishidden" "ishidden"

	copy_property r origLight "AreaWidth" "photometricRadius"

	-- ies file
	filename = get_property origLight "filename"
	if filename != "" and filename != undefined do (
		plugcfg = GetDir #plugcfg
		profile_path = plugcfg + "\\Radeon ProRender\\IES Profiles\\"
		makeDir (profile_path)
		ies_file = filename
		ies_name = (filterString ies_file "\\")
		ies_name = ies_name[ies_name.count]
		copyFile (ies_file) (profile_path + ies_name)
		set_property r "profile" ies_name
	)

	-- Intensitiy, Color, Texmap
	if get_property origLight "useColor" then (
		set_property r "colorMode" 0
	) else (
		set_property r "colorMode" 1
	)

	ai_res_int = get_property origLight "intensity"
	rpr_intensity = 0.0001 * ai_res_int ^ 3 + 0.0082 * ai_res_int ^ 2 + 0.3116 * ai_res_int + 0.7513
	set_property r "intensity" rpr_intensity
	copy_property r origLight "color" "color"
	copy_property r origLight "temperature" "kelvin"

	-- logging
	end_log origLight

	r
)

fn convertIBL origLight = (
	if get_property origLight "on" do(
		rpr = Radeon_ProRender()

		-- log to file 
		start_log origLight rpr

		set_property rpr "backgroundOverride" true
		set_property rpr "backgroundType" 0

		if get_property origLight "useKelvin" then (
			temp_color = convertTemperature (get_property origLight "kelvin")
			set_property rpr "backgroundColor" temp_color
		) else (
			copy_property rpr origLight "backgroundColor" "color"
		)

		if get_property origLight "useTexmap" then (
			set_property rpr "useBackgroundMap" true
			copy_property rpr origLight "backgroundMap" "texmap"
		) else (
			set_property rpr "backgroundMap" undefined
		)

		set_property rpr "backgroundIntensity" (get_property origLight "intensity" * 2.0 ^ get_property origLight "exposure")

		-- logging
		end_log origLight
	)

	"no_replace"
)

fn convertPhysicalLight origLight = (
	local r = physical_light()
	r.name = origLight.name + rprPostfixStr

	-- log to file 
	start_log origLight r

	-- On/Off, Include/exclude
	copy_property r origLight "isEnabled" "on"
	copy_property r origLight "isTargeted" "targeted"
	copy_property r origLight "DistanceToTarget" "targdist"

	-- position conversion
	set_property origLight "targeted" false
	copy_property r origLight "pos" "pos"
	--copy_property r origLight "rotation" "rotation"
	copy_property r origLight "scale" "scale"
	copy_property r origLight "pivot" "pivot"
	copy_property r origLight "transform" "transform"
	copy_property r origLight "dir" "dir"

	light_type = get_property origLight "shapeType"

	if light_type == 0 then ( -- point
		set_property r "lightType" 2
		set_property r "LightIntensity" ((0.0334 * get_property origLight "intensity" * 2.0 ^ get_property origLight "exposure") ^ 0.8696)
	) else if light_type == 1 then ( -- directional
		set_property r "lightType" 3
		set_property r "LightIntensity" (get_property origLight "intensity" * 2.0 ^ get_property origLight "exposure")
		r.LightIntensity = origLight.intensity * 2.0^origLight.exposure 
	) else if light_type == 2 then ( -- spot
		set_property r "lightType" 1
		set_property r "LightIntensity" (get_property origLight "intensity" * 2.0 ^ get_property origLight "exposure")

		copy_property r origLight "OuterConeFalloff" "Cone_Angle"
		set_property r "InnerConeAngle" (-0.986 * get_property origLight "penumbra_angle" + get_property origLight "Cone_Angle")

	) else ( -- area
		set_property r "lightType" 0
		set_property r "LightIntensity" (get_property origLight "intensity" * 2.0 ^ get_property origLight "exposure")

		if light_type == 3 do ( -- rect / quad
			set_property r "areaShape" 3
			copy_property r origLight "areaWidths" "quadX"
			copy_property r origLight "areaLength" "quadY"
		)

		if light_type == 4 do ( -- disc
			set_property r "areaShape" 0
			set_property r "areaWidths" (get_property origLight "lightRadius" * 2)
		)

		if light_type == 5 do ( -- cylinder
			set_property r "areaShape" 1
			set_property r "areaWidths" (get_property origLight "lightRadius" * 2)
			copy_property r origLight "areaWidths" "height"

		)

		if light_type == 8 do ( -- mesh
			set_property r "areaShape" 4
		)
	)

	-- Intensitiy, Color, Texmap
	if get_property origLight "useColor" then (
		set_property r "ColourMode" 0
	) else (
		set_property r "ColourMode" 1
	)

	copy_property r origLight "ColourPicker" "color"
	copy_property r origLight "temperature" "kelvin"

	-- logging
	end_log origLight

	r
)

fn convertArnoldLight origLight = (
	light_type = get_property origLight "shapeType"

	physical_light_types = #(0, 1, 2, 3, 4, 5, 8)
	if findItem physical_light_types light_type then (
		r = convertPhysicalLight origLight 
	) else if light_type == 6 then (
		r = convertIBL origLight
	) else if light_type == 7 do (
		r = convertIesLight origLight
	)

	r
)

/*
 ENVIRONMENT CONVERSION
*/

fn convert3dsMaxEnvironment =(
	rpr = Radeon_ProRender()

	-- log to file 
	start_log "3dsMax Environment" rpr

	set_property rpr "backgroundOverride" true
	set_property rpr "backgroundType" 0

	set_property rpr "backgroundColor" backgroundColor
	
	if useEnvironmentMap do (
		set_property rpr "useBackgroundMap" true
		set_property rpr "backgroundMap" environmentMap
	)

	set_property rpr "backgroundIntensity" 1.0

	-- log to file 
	end_log "3dsMax Environment"

)

fn convertAiAtmosphereVolume origEnv =(
	local r = Sphere()
	r.name = "aiAtmosphereVolume_rpr"
	r.scale = [10000, 10000, 10000]

	-- assign volume material to sphere
	volume_shader = RPR_Volume_Material()
	r.material = volume_shader

	copy_property volume_shader origEnv "color" "rgb_density"
	copy_property volume_shader origEnv "colorTexmap" "rgb_density_shader"
	copy_property volume_shader origEnv "distance" "density"
	copy_property volume_shader origEnv "distanceTexmap" "density_shader"

)

fn convertAiFog origEnv =(
	local r = Box()
	r.name = "aiFog_rpr"
	r.scale = [10000, 10000, 10000]

	-- assign volume material to sphere
	volume_shader = RPR_Volume_Material()
	r.material = volume_shader

	copy_property volume_shader origEnv "color" "color"
	copy_property volume_shader origEnv "colorTexmap" "color_shader"
	copy_property volume_shader origEnv "distance" "distance"
	copy_property volume_shader origEnv "distanceTexmap" "distance_shader"

)

/*
 CONVERT FUNCTIONS
*/

fn convertLight orig_light =(
	if superclassof orig_light != light then return orig_light  -- check if this is a light; if not, just return the value
	
	local i = findItem orig_lights orig_light -- check if we have already converted this light
	if i > 0 do return new_lights[i]  --if yes, just return the already converted one	
	
	cls=classof orig_light
	local new_light=case cls of (
		Arnold_Light: errorCatching convertArnoldLight orig_light 
		default: orig_light
	)
	
	if new_light != orig_light then ( 		-- if converted, add to the list of converted lights
		append orig_lights orig_light
		append new_lights new_light
	)
	
	new_light
)


fn convertMaterial orig_mtl =(
		
	local i = findItem orig_mtls orig_mtl -- check if we have already converted this material
	if i > 0 then return new_mtls[i]  --if yes, just return the already converted one	
	
	cls = classof orig_mtl
	local new_mtl = case cls of (
		-- MATERIALS
		Multimaterial: errorCatching convertMultimaterial orig_mtl
		ai_standard_surface: errorCatching convertAiStandardSurface orig_mtl
		ai_layer_shader: errorCatching convertAiLayerShader orig_mtl
		ai_car_paint: errorCatching convertAiCarPaint orig_mtl
		ai_mix_shader: errorCatching convertAiMixShader orig_mtl 
		ArnoldMapToMtl: errorCatching convertArnoldMapToMtl orig_mtl 
		 
		--following materials will be replaced with default green rpr uber mat, will be supported later
		ai_lambert: errorCatching convertUnsupportedMtl orig_mtl 
		ai_matte: errorCatching convertUnsupportedMtl orig_mtl 
		ai_standard_hair: errorCatching convertUnsupportedMtl orig_mtl 
		ai_two_sided: errorCatching convertUnsupportedMtl orig_mtl 
		ai_passthrough: errorCatching convertUnsupportedMtl orig_mtl 
		ai_ray_switch_shader: errorCatching convertUnsupportedMtl orig_mtl
		ai_switch_shader: errorCatching convertUnsupportedMtl orig_mtl 
		ai_trace_set: errorCatching convertUnsupportedMtl orig_mtl 
		ai_standard_volume: errorCatching convertUnsupportedMtl orig_mtl 
		ai_aov_write_float: errorCatching convertUnsupportedMtl orig_mtl 
		ai_aov_write_int: errorCatching convertUnsupportedMtl orig_mtl 
		ai_aov_write_rgb: errorCatching convertUnsupportedMtl orig_mtl 
		ai_aov_write_rgba: errorCatching convertUnsupportedMtl orig_mtl
		
		-- UTILITIES
		OSLMap: errorCatching convertOSLMap orig_mtl
		ai_add: errorCatching convertMathUtility orig_mtl
		ai_subtract: errorCatching convertMathUtility orig_mtl
		ai_multiply: errorCatching convertMathUtility orig_mtl
		ai_divide: errorCatching convertMathUtility orig_mtl
		ai_max: errorCatching convertMathUtility orig_mtl
		ai_min: errorCatching convertMathUtility orig_mtl
		ai_pow: errorCatching convertAiPow orig_mtl
		ai_normalize: errorCatching convertMathUtilityOneChannel orig_mtl
		ai_atan: errorCatching convertAiAtan orig_mtl
		ai_cross: errorCatching convertMathUtility orig_mtl
		ai_abs: errorCatching convertMathUtilityOneChannel orig_mtl
		ai_dot: errorCatching convertMathUtility orig_mtl
		ai_bump2d: errorCatching convertAiBump orig_mtl
		ai_bump3d: errorCatching convertAiBump orig_mtl
		ai_normal_map: errorCatching convertAiNormalMap orig_mtl
		ai_vector_map: errorCatching convertAiVectorMap orig_mtl
		ai_exp: errorCatching convertAiExp orig_mtl
		ai_ambient_occlusion: errorCatching convertAiAO orig_mtl
		ai_sqrt: errorCatching convertAiSqrt orig_mtl
		ai_modulo: errorCatching convertAiModulo orig_mtl
		ai_mix_rgba: errorCatching convertAiMixRGBA orig_mtl	
		ai_color_correct: errorCatching convertAiColorCorrect orig_mtl
		ai_shadow_matte: errorCatching convertAiShadowMatte orig_mtl 
		ai_blackbody: errorCatching convertAiBlackbody orig_mtl
		ai_flat: errorCatching convertAiFlat orig_mtl
		ai_negate: errorCatching convertAiNegate orig_mtl
		ai_toon: errorCatching convertAiToon orig_mtl
		ai_reciprocal: errorCatching convertAiReciprocal orig_mtl
		ai_vector_to_rgb: errorCatching convertAiVectorToRGB orig_mtl
		ai_sign: errorCatching convertAiSign orig_mtl
		ai_trigo: errorCatching convertAiTrigo orig_mtl
		ai_layer_rgba: errorCatching convertAiLayerRGBA orig_mtl

		--following utilies will be replaced with default rpr arithmetic node, will be supported later
		ai_round_corners: errorCatching convertUnsupportedUtility orig_mtl
		ai_color_convert: errorCatching convertUnsupportedUtility orig_mtl
		ai_color_jitter: errorCatching convertUnsupportedUtility orig_mtl
		ai_float_to_int: errorCatching convertUnsupportedUtility orig_mtl
		ai_float_to_matrix: errorCatching convertUnsupportedUtility orig_mtl
		ai_float_to_rgb: errorCatching convertUnsupportedUtility orig_mtl
		ai_float_to_rgba: errorCatching convertUnsupportedUtility orig_mtl
		ai_rgb_to_float: errorCatching convertUnsupportedUtility orig_mtl
		ai_rgba_to_float: errorCatching convertUnsupportedUtility orig_mtl
		ai_rgb_to_vector: errorCatching convertUnsupportedUtility orig_mtl
		ai_shuffle: errorCatching convertUnsupportedUtility orig_mtl
		ai_physical_sky: errorCatching convertUnsupportedUtility orig_mtl
		ai_compare: errorCatching convertUnsupportedUtility orig_mtl
		ai_complement: errorCatching convertUnsupportedUtility orig_mtl
		ai_fraction: errorCatching convertUnsupportedUtility orig_mtl
		ai_is_finite: errorCatching convertUnsupportedUtility orig_mtl
		ai_length: errorCatching convertUnsupportedUtility orig_mtl
		ai_log: errorCatching convertUnsupportedUtility orig_mtl
		ai_matrix_transform: errorCatching convertUnsupportedUtility orig_mtl
		ai_matrix_multiply_vector: errorCatching convertUnsupportedUtility orig_mtl
		ai_random: errorCatching convertUnsupportedUtility orig_mtl
		ai_range: errorCatching convertUnsupportedUtility orig_mtl
		ai_space_transform: errorCatching convertUnsupportedUtility orig_mtl
		ai_state_float: errorCatching convertUnsupportedUtility orig_mtl
		ai_state_int: errorCatching convertUnsupportedUtility orig_mtl
		ai_state_vector: errorCatching convertUnsupportedUtility orig_mtl
		ai_complex_ior: errorCatching convertUnsupportedUtility orig_mtl
		ai_flakes: errorCatching convertUnsupportedUtility orig_mtl
		ai_noise: errorCatching convertUnsupportedUtility orig_mtl
		ai_camera_projection: errorCatching convertUnsupportedUtility orig_mtl
		ai_cell_noise: errorCatching convertUnsupportedUtility orig_mtl
		ai_checkerboard: errorCatching convertUnsupportedUtility orig_mtl
		ai_image: errorCatching convertUnsupportedUtility orig_mtl
		
		ai_layer_float: errorCatching convertUnsupportedUtility orig_mtl
		ai_ramp_rgb: errorCatching convertUnsupportedUtility orig_mtl
		ai_ramp_float: errorCatching convertUnsupportedUtility orig_mtl
		ai_triplanar: errorCatching convertUnsupportedUtility orig_mtl
		ai_user_data_rgb: errorCatching convertUnsupportedUtility orig_mtl
		ai_user_data_rgba: errorCatching convertUnsupportedUtility orig_mtl
		ai_user_data_float: errorCatching convertUnsupportedUtility orig_mtl
		ai_user_data_int: errorCatching convertUnsupportedUtility orig_mtl
		ai_user_data_string: errorCatching convertUnsupportedUtility orig_mtl
		ai_cache: errorCatching convertUnsupportedUtility orig_mtl
		ai_clamp: errorCatching convertUnsupportedUtility orig_mtl
		ai_curvature: errorCatching convertUnsupportedUtility orig_mtl
		ai_facing_ratio: errorCatching convertUnsupportedUtility orig_mtl
		ai_motion_vector: errorCatching convertUnsupportedUtility orig_mtl
		ai_ray_switch_rgba: errorCatching convertUnsupportedUtility orig_mtl
		ai_switch_rgba: errorCatching convertUnsupportedUtility orig_mtl
		ai_utility: errorCatching convertUnsupportedUtility orig_mtl
		ai_uv_projection: errorCatching convertUnsupportedUtility orig_mtl
		ai_uv_transform: errorCatching convertUnsupportedUtility orig_mtl
		ai_wireframe: errorCatching convertUnsupportedUtility orig_mtl
		ai_volume_sample_float: errorCatching convertUnsupportedUtility orig_mtl
		ai_volume_sample_rgb: errorCatching convertUnsupportedUtility orig_mtl
		ai_cryptomatte: errorCatching convertUnsupportedUtility orig_mtl

		default: orig_mtl
	)
	
	if new_mtl != orig_mtl then ( 		-- if converted, add to the list of converted materials
		append orig_mtls orig_mtl
		append new_mtls new_mtl
	)
	
	new_mtl
)

fn convertEnvironment =(

	-- fog and atmosphere conversion
	env = get_property renderers.current "atmosphere"
	cls = classof env
	case cls of (
		ai_fog: errorCatching convertAiFog env 
		ai_atmosphere_volume: errorCatching convertAiAtmosphereVolume env 
	)

	convert3dsMaxEnvironment()
)

fn cleanUpConversionData =(

	delete (for elem in orig_lights where (superclassof elem == light) and isvalidnode elem collect elem) 

	-- delete AOVs
	try (
		re = maxOps.GetCurRenderElementMgr()
	    re.removeallrenderelements()
	) catch ()

	orig_mtls=#()
	new_mtls=#()
	orig_lights=#()
	new_lights=#()

	clearUndoBuffer()
	true
)

--get all objects with such material
fn getObjsFromMaterial current_material  =(
	obj_arr = for o in geometry where o.material == current_material collect o
	return obj_arr
)

fn convertScene =(
	
	start = timeStamp()

	startConversion()

	ai = Arnold()
	if classof renderers.current != classof ai do renderers.current = ai

	-- Environment conversion
	convertEnvironment()

	-- material conversion
	aiMtlClasses = #("ai_standard_surface", "ai_car_paint", "ai_lambert", "ai_layer_shader", "ai_matte", \
		"ai_standard_hair", "ai_two_sided", "ArnoldMapToMtl", "ai_passthrough", "ai_ray_switch_shader", "ai_switch_shader", \
		"ai_trace_set", "ai_standard_volume", "ai_mix_shader", "ai_atmosphere_volume", "ai_fog", "ai_aov_write_float", "ai_aov_write_int", \
		"ai_aov_write_rgb", "ai_aov_write_rgba")


	for c in aiMtlClasses do ( --where c.creatable 
		cls = execute c -- execute obj from string
		if classof cls == material do( -- check superclass
			clssInst = getclassinstances cls -- get all class instances from scene
			for i in clssInst do (
				obj_arr = getObjsFromMaterial i -- get all geometry from this material
				if obj_arr.count > 0 do (
					newMat = convertMaterial i -- convert material
					if newMat != "no_replace" do (
						for g in obj_arr do g.material = newMat -- replace arnold material
					)
				)
			)
		)
	)

	-- light conversion
	allLights = for o in objects where superclassof o == light and o.category == #Arnold collect o
	for i in allLights do convertLight i

	renderers.current = Radeon_ProRender()
	renderers.current.raycastEpsilon = 0.001
	renderers.current.texturecompression = true

	end = timeStamp()
	total_time = (end - start) / 1000.0
	print("Scene conversion took " + total_time as string + " seconds.")
	print("Converted: " + new_mtls.count as string + " materials, " + new_lights.count as string + " lights.")
	finishConversion total_time

	cleanUpConversionData()
	
)

if not globalVars.isglobal(#autoLaunch) do (
     convertScene()
)

