
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

orig_shps=#()
new_shps=#()
orig_mtls=#()
new_mtls=#()
orig_maps=#()
new_maps=#()
orig_lights=#()
new_lights=#()
orig_cameras=#()
new_cameras=#()

unsupportedPostfixStr = "_unsupported"
rprPostfixStr = "_rpr"

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


/* 
    MATERIALS
*/


fn convertUnsupportedMtl origMtl =(
	r = RPR_Uber_Material()
	r.name = origMtl.name + unsupportedPostfixStr
	r.diffuseColor = color 0 45 0
	r
)


fn convertAiStandardSurface origMtl =(
	r = RPR_Uber_Material()
	r.name = origMtl.name + rprPostfixStr

	-- diffuse
	if origMtl.base > 0 or origMtl.base_color_shader != undefined do ( r.DiffuseEnable = true )
	r.DiffuseColor = origMtl.base_color
	r.DiffuseColorTexmap = origMtl.base_color_shader
	r.DiffuseWeight = origMtl.base
	r.DiffuseWeightTexmap = origMtl.base_shader
	r.DiffuseRoughness = origMtl.diffuse_roughness
	r.DiffuseRoughnessTexmap = origMtl.diffuse_roughness_shader

	r.RefractionAllowCaustics = origMtl.caustics
	
	-- reflection
	if origMtl.specular > 0 or origMtl.specular_color_shader != undefined do ( r.reflectionEnable = true )
	r.reflectionColor = origMtl.specular_color
	r.reflectionColorTexmap = origMtl.specular_color_shader
	r.reflectionWeight = origMtl.specular
	r.ReflectionWeightTexmap = origMtl.specular_shader
	r.reflectionRoughness = origMtl.specular_roughness
	r.reflectionRoughnessTexmap = origMtl.specular_roughness_shader

	if origMtl.metalness > 0 or origMtl.metalness_shader != undefined do ( 
		r.DiffuseEnable = true
		r.reflectionEnable = true
		r.refractionEnable = true
		r.reflectionEnable = true
		r.reflectionMode = 2
		r.reflectionColor = origMtl.base_color
		r.reflectionColorTexmap = origMtl.base_color_shader
	)

	r.reflectionIor = origMtl.specular_IOR
	r.reflectionIorTexmap = origMtl.specular_IOR_shader
	r.reflectionMetalness = origMtl.metalness
	r.reflectionMetalnessTexmap = origMtl.metalness_shader

	r.reflectionAnisotropy = origMtl.specular_anisotropy
	r.reflectionAnisotropyTexmap = origMtl.specular_anisotropy_shader
	r.reflectionAnisotropyRotation = origMtl.specular_rotation
	r.reflectionAnisotropyRotationTexmap = origMtl.specular_rotation_shader

	-- refraction
	if origMtl.transmission > 0 or origMtl.transmission_shader != undefined do ( r.refractionEnable = true )
	r.RefractionWeight = origMtl.transmission
	r.RefractionWeightTexmap = origMtl.transmission_shader
	r.RefractionColor = origMtl.transmission_color
	r.RefractionColorTexmap = origMtl.transmission_color_shader
	r.RefractionRoughness = origMtl.specular_roughness
	r.RefractionRoughnessTexmap = origMtl.specular_roughness_shader
	r.RefractionThinSurface = origMtl.thin_walled
	r.RefractionIor = origMtl.specular_IOR
	r.RefractionIorTexmap = origMtl.specular_IOR_shader

	r.RefractionAbsorptionDistance = origMtl.transmission_depth

	-- subsurface
	if origMtl.subsurface > 0 or origMtl.subsurface_shader != undefined do ( 
		r.SssEnable = true 
		r.DiffuseEnable = true
		r.DiffuseWeight = 1
		r.DiffuseBackscatteringWeight = 0.75
		r.DiffuseBackScatteringColor = origMtl.subsurface_color
		r.DiffuseBackScatteringColorTexmap = origMtl.subsurface_color_shader
	)
	r.SssWeight = origMtl.subsurface
	r.SssWeightTexmap = origMtl.subsurface_shader
	r.SssColor = origMtl.subsurface_color
	r.SssColorTexmap = origMtl.subsurface_color_shader
	r.SssRadius = origMtl.subsurface_radius
	r.SssRadiusTexmap = origMtl.subsurface_radius_shader

	-- coat
	if origMtl.coat > 0 or origMtl.coat_shader != undefined do ( r.CoatingEnable = true )
	r.CoatingWeight = origMtl.coat
	r.CoatingWeightTexmap = origMtl.coat_shader

	if origMtl.coat_color == color 255 255 255 and origMtl.coat_shader == undefined then (
		r.CoatingColor = origMtl.coat_color
		r.CoatingColorTexmap = origMtl.coat_color_shader
	) else if origMtl.coat_shader == undefined then (
		r.CoatingColor = color 255 255 255
		arith = RPR_Arithmetic()
		arith.operator = 2
		arith.Color1 = origMtl.base_color
		arith.color0texmap = origMtl.base_color_shader
		arith.Color2 = origMtl.coat_color
		arith.color1texmap = origMtl.coat_color_shader
		r.diffuseColorTexmap = arith
	) else (
		r.CoatingColor = color 255 255 255
		blend_value = RPR_Blend_Value()
		blend_value.Color1 = origMtl.base_color
		blend_value.color0Texmap = origMtl.base_color_shader

		arith = RPR_Arithmetic()
		arith.operator = 2
		arith.Color1 = origMtl.base_color
		arith.color0texmap = origMtl.base_color_shader
		arith.Color2 = origMtl.coat_color
		arith.color1texmap = origMtl.coat_color_shader

		blend_value.color1Texmap = arith
		blend_value.weightTexmap = origMtl.coat_shader
		r.diffuseColorTexmap = blend_value
	)

	r.CoatingRoughness = origMtl.coat_roughness
	r.CoatingRoughnessTexmap = origMtl.coat_roughness_shader
	r.CoatingIor = origMtl.coat_IOR
	r.CoatingIorTexmap = origMtl.coat_IOR_shader
	r.CoatingNormalTexmap = origMtl.coat_normal_shader
	r.CoatingThickness = 1.5

	-- emission
	if origMtl.emission > 0 or origMtl.emission_color_shader != undefined do ( r.emissiveEnable = true )
	r.EmissiveWeight = 0.35
	r.EmissiveColor = origMtl.emission_color
	r.EmissiveColorTexmap = origMtl.emission_color_shader
	r.EmissiveIntensity = origMtl.emission * 2.5

	if origMtl.opacity != color 255 255 255 then (
		r.TransparencyEnable = true
		opacity_color = amax #(origMtl.opacity.red, origMtl.opacity.green, origMtl.opacity.blue)
		r.Transparency = opacity_color
	)

	if origMtl.opacity_shader != undefined do (
		r.TransparencyEnable = true
		arith = RPR_Arithmetic()
		arith.operator = 1
		arith.Color1 = color 255 255 255
		arith.color1texmap = origMtl.opacity_shader
		r.transparencyTexmap = arith
	)

	if origMtl.normal_shader != undefined do (
		r.normalEnable = true
		r.normalTexmap = origMtl.normal_shader
	)

	r
)

fn convertAiCarPaint origMtl =(
	r = RPR_Uber_Material()
	r.name = origMtl.name + rprPostfixStr

	-- diffuse
	if origMtl.base > 0 or origMtl.base_color_shader != undefined do ( r.DiffuseEnable = true )
	r.DiffuseColor = origMtl.base_color
	r.DiffuseColorTexmap = origMtl.base_color_shader
	r.DiffuseWeight = origMtl.base
	r.DiffuseWeightTexmap = origMtl.base_shader
	r.DiffuseRoughness = origMtl.base_roughness
	r.DiffuseRoughnessTexmap = origMtl.base_roughness_shader
	
	-- reflection
	if origMtl.specular > 0 or origMtl.specular_color_shader != undefined do ( r.reflectionEnable = true )
	r.reflectionColor = origMtl.specular_color
	r.reflectionColorTexmap = origMtl.specular_color_shader
	r.reflectionWeight = origMtl.specular
	r.ReflectionWeightTexmap = origMtl.specular_shader
	r.reflectionRoughness = origMtl.specular_roughness
	r.reflectionRoughnessTexmap = origMtl.specular_roughness_shader
	r.reflectionIor = origMtl.specular_IOR
	r.reflectionIorTexmap = origMtl.specular_IOR_shader

	-- coat
	if origMtl.coat > 0 or origMtl.coat_shader != undefined do ( r.CoatingEnable = true )
	r.CoatingWeight = origMtl.coat
	r.CoatingWeightTexmap = origMtl.coat_shader

	if origMtl.coat_color == color 255 255 255 and origMtl.coat_shader == undefined then (
		r.CoatingColor = origMtl.coat_color
		r.CoatingColorTexmap = origMtl.coat_color_shader
	) else if origMtl.coat_shader == undefined then (
		r.CoatingColor = color 255 255 255
		arith = RPR_Arithmetic()
		arith.operator = 2
		arith.Color1 = origMtl.base_color
		arith.color0texmap = origMtl.base_color_shader
		arith.Color2 = origMtl.coat_color
		arith.color1texmap = origMtl.coat_color_shader
		r.diffuseColorTexmap = arith
	) else (
		r.CoatingColor = color 255 255 255
		blend_value = RPR_Blend_Value()
		blend_value.Color1 = origMtl.base_color
		blend_value.color0Texmap = origMtl.base_color_shader

		arith = RPR_Arithmetic()
		arith.operator = 2
		arith.Color1 = origMtl.base_color
		arith.color0texmap = origMtl.base_color_shader
		arith.Color2 = origMtl.coat_color
		arith.color1texmap = origMtl.coat_color_shader

		blend_value.color1Texmap = arith
		blend_value.weightTexmap = origMtl.coat_shader
		r.diffuseColorTexmap = blend_value
	)

	r.CoatingRoughness = origMtl.coat_roughness
	r.CoatingRoughnessTexmap = origMtl.coat_roughness_shader
	r.CoatingIor = origMtl.coat_IOR
	r.CoatingIorTexmap = origMtl.coat_IOR_shader

	if origMtl.coat_normal_shader != undefined do (
		r.normalEnable = true
		r.normalTexmap = origMtl.coat_normal_shader
	)

	r
)

fn convertAiLayerShader origMtl =(
	r = RPR_Blend_Material()
	r.name = origMtl.name + rprPostfixStr

	materials = #()
	if origMtl.enable1 do (
		if origMtl.input1 != undefined do (
			append materials origMtl.input1
		)
	)
	if origMtl.enable2 do (
		if origMtl.input2 != undefined do (
			append materials #(origMtl.input2, origMtl.mix2, origMtl.mix2_shader)
		)
	)
	if origMtl.enable3 do (
		if origMtl.input3 != undefined do (
			append materials #(origMtl.input3, origMtl.mix3, origMtl.mix3_shader)
		)
	)
	if origMtl.enable4 do (
		if origMtl.input4 != undefined do (
			append materials #(origMtl.input4, origMtl.mix4, origMtl.mix4_shader)
		)
	)
	if origMtl.enable5 do (
		if origMtl.input5 != undefined do (
			append materials #(origMtl.input5, origMtl.mix5, origMtl.mix5_shader)
		)
	)
	if origMtl.enable6 do (
		if origMtl.input6 != undefined do (
			append materials #(origMtl.input6, origMtl.mix6, origMtl.mix6_shader)
		)
	)
	if origMtl.enable7 do (
		if origMtl.input7 != undefined do (
			append materials #(origMtl.input7, origMtl.mix7, origMtl.mix7_shader)
		)
	)
	if origMtl.enable8 do (
		if origMtl.input8 != undefined do (
			append materials #(origMtl.input8, origMtl.mix8, origMtl.mix8_shader)
		)
	)

	r.material1 = materials[1]
	deleteItem materials 1

	-- materials conversion
	first_material = true
	for mat in materials do (
		if first_material then (
			r.material2 = mat[1]
			r.weight = mat[2]
			r.weightMap = mat[3]
			first_material = false
		) else (
			old_r = r
			r = RPR_Blend_Material()
			r.material1 = old_r
			r.material2 = mat[1]
			r.weight = mat[2]
			r.weightMap = mat[3]
		)		
	)
	
	r
)

/* 
    UTILITIES
*/

fn convertUnsupportedUtility origMap =(
	r = RPR_Arithmetic()
	r.name = origMap.name + unsupportedPostfixStr
	r
)

fn convertColorOSL origMap operator = (
	r = RPR_Arithmetic()
	r.name = origMap.name + rprPostfixStr

	r.operator = operator
	r.Color1 = origMap.A
	r.Color2 = origMap.B
	r.color0texmap = origMap.A_map
	r.color1texmap = origMap.B_map
	r
)

fn convertColorClampOSL origMap = (
	r = RPR_Arithmetic()
	r.name = origMap.name + rprPostfixStr

	r.operator = 12

	arith = RPR_Arithmetic()
	arith.operator = 13
	arith.Color1 = origMap.Input
	arith.Color2 = origMap.min
	arith.color0texmap = origMap.Input_map
	arith.color1texmap = origMap.Min_map

	r.color0texmap = arith
	r.Color2 = origMap.max
	r.color1texmap = origMap.Max_map

	r
)

fn convertColorCompOSL origMap = (
	r = RPR_Arithmetic()
	r.name = origMap.name + rprPostfixStr

	r.operator = 1

	r.Color1 = color 255 255 255
	r.Color2 = origMap.input
	r.color1texmap = origMap.input_map

	r
)

fn convertOSLMap origMap = (

	OSLPath = origMap.OSLPath
	OSLFile = (filterString OSLPath "\\")
	OSLFile = OSLFile[OSLFile.count]
	local new_osl=case OSLFile of (
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
	r = RPR_Arithmetic()
	r.name = origMap.name + rprPostfixStr

	cls=classof origMap
	local operator=case cls of (
		ai_add: 0
		ai_subtract: 1
		ai_multiply: 2
		ai_divide: 3
		ai_max: 13
		ai_min: 12
		ai_pow: 11
		ai_normalize: 16
		ai_atan: 21
		ai_cross: 22
		ai_dot: 10
		
		default: 0
	)

	r.operator = operator
	r.Color1 = origMap.input1
	r.Color2 = origMap.input2
	r.color0texmap = origMap.input1_shader
	r.color1texmap = origMap.input2_shader

	r
)

fn convertAiAbs origMap =(
	r = RPR_Arithmetic()
	r.name = origMap.name + rprPostfixStr

	r.operator = 17
	r.Color1 = origMap.input
	r.color0texmap = origMap.input_shader

	r
)

fn convertAiExp origMap =(
	r = RPR_Arithmetic()
	r.name = origMap.name + rprPostfixStr

	e = 2.718
	base_color = #(remap_value origMap.input.red 255 0 1 0, remap_value origMap.input.green 255 0 1 0, remap_value origMap.input.blue 255 0 1 0)
	exp_color = #(2.718^base_color[1], 2.718^base_color[2], 2.718^base_color[1])
	for i=1 to exp_color.count do(
		if exp_color[i]>1 then(
			exp_color[i] = 255
		) else (
			exp_color[i] = remap_value exp_color[i] 1 0 255 0
		)
	)

	r.operator = 0
	r.Color1 = color exp_color[1] exp_color[2] exp_color[3]
	r.Color2 = color 255 255 255

	r
)

fn convertAiNormalMap origMap = (
	r = RPR_Normal()
	r.name = origMap.name + rprPostfixStr
	
	if origMap.input_shader != undefined then (
		r.map = origMap.input_shader
	) else (
		r.map = origMap.normal_shader
	)

	if origMap.strength > 1.0 then (
		r.strength = 1.0
	) else (
		r.strength = origMap.strength
	)

	r
)

fn convertAiBump2d origMap = (
	r = RPR_Normal()
	r.name = origMap.name + rprPostfixStr
	
	r.isBump = true

	if origMap.bump_map_shader != undefined then (
		r.map = origMap.bump_map_shader
	) else (
		r.map = origMap.normal_shader
	)

	if origMap.bump_height * 100.0 > 1.0 then (
		r.strength = 1.0
	) else (
		r.strength = origMap.bump_height * 100.0
	)

	r
)

fn convertAiBump3d origMap = (
	r = RPR_Normal()
	r.name = origMap.name + rprPostfixStr
	
	r.isBump = true

	if origMap.bump_map_shader != undefined then (
		r.map = origMap.bump_map_shader
	) else (
		r.map = origMap.normal_shader
	)

	if origMap.bump_height * 100.0 > 1.0 then (
		r.strength = 1.0
	) else (
		r.strength = origMap.bump_height * 100.0
	)

	r
)

fn convertAiVectorMap origMap = (
	r = RPR_Normal()
	r.name = origMap.name + rprPostfixStr
	
	if origMap.input_shader != undefined then (
		r.map = origMap.input_shader
	) else (
		r.map = origMap.normal_shader
	)

	if origMap.scale > 1.0 then (
		r.strength = 1.0
	) else (
		r.strength = origMap.scale
	)

	r
)

/* 
    LIGHTS
*/

fn convertIesLight origLight = (
	r = ies_light()
	origLight.name += rprPostfixStr

	-- On/Off, Include/exclude
	r.enabled = origLight.on
	r.targeted = origLight.targeted

	-- ies file
	if origLight.filename != "" and origLight.filename != undefined do (
		plugcfg = GetDir #plugcfg
		profile_path = plugcfg + "\\Radeon ProRender\\IES Profiles\\"
		makeDir (profile_path)
		ies_file = origLight.filename
		ies_name = (filterString ies_file "\\")
		ies_name = ies_name[ies_name.count]
		copyFile (ies_file) (profile_path + ies_name)
		r.profile = ies_name
	)

	-- Intensitiy, Color, Texmap
	if origLight.useColor then (
		r.colorMode = 0
	) else (
		r.colorMode = 1
	)
	r.intensity = origLight.intensity * (origLight.exposure + 5.0) / 1070.0
	r.color = origLight.color
	r.temperature = origLight.kelvin

	r
)

fn convertIBL origLight = (

	if origLight.on then(
		rpr = Radeon_ProRender()
		rpr.backgroundOverride = true
		rpr.backgroundType = 0

		if origLight.useColor do (
			r.backgroundColor = origLight.color
		)

		if origLight.useTexmap do (
			rpr.useBackgroundMap = True
			rpr.backgroundMap =  origLight.texmap
		)

		rpr.backgroundIntensity = origLight.intensity

	) else (
		delete origLight
		r = "no_replace"
	)
	r
)

fn convertPhysicalLight origLight = (

	r = physical_light()
	origLight.name += rprPostfixStr

	r.isEnabled = origLight.on 
	light_type = origLight.shapeType

	if light_type == 0 then ( -- point
		r.lightType = 2
	) else if light_type == 1 then ( -- directional
		r.lightType = 3
	) else if light_type == 2 then ( -- spot
		r.lightType = 1
	) else ( -- area
		r.lightType = 0

		if light_type == 3 do ( -- rect / quad
			r.areaShape = 3
		)

		if light_type == 4 do ( -- disc
			r.areaShape = 0
		)

		if light_type == 5 do ( -- cylinder
			r.areaShape = 1
		)

		if light_type == 8 do ( -- mesh
			r.areaShape = 4
		)
	)

	-- Intensitiy, Color, Texmap
	if origLight.useColor then (
		r.ColourMode = 0
	) else (
		r.ColourMode = 1
	)
	r.LightIntensity = origLight.intensity / 160.0 * 2.0^origLight.exposure 
	r.ColourPicker = origLight.color
	r.temperature = origLight.kelvin

	r
)

fn convertArnoldLight origLight = (
	
	light_type = origLight.shapeType

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


fn convertLight orig_light =(
	if ((superclassof orig_light)!=light) then return orig_light  -- check if this is a light; if not, just return the value
	
	local i=findItem orig_lights orig_light -- check if we have already converted this light
	if i>0 then return new_lights[i]  --if yes, just return the already converted one	
	
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


fn convertUtility orig_map =(
	if ((superclassof orig_map)!=textureMap) then return orig_map  -- check if this is a material; if not, just return the value
	
	local i=findItem orig_maps orig_map -- check if we have already converted this map
	if i>0 then return new_maps[i]  --if yes, just return the already converted one	
	
	-- recurse into sub-maps, if any
	local sub_count=getNumSubTexmaps orig_map
	if sub_count >= 1 then (
		for i=1 to sub_count do (
			subMap = getSubTexmap orig_map i
			if subMap != undefined do (
				newMap = convertUtility subMap
				setSubTexmap orig_map i newMap
			)
		)
	)
	
	cls=classof orig_map
	
	local new_map=case cls of (		
		OSLMap: errorCatching convertOSLMap orig_map
		ai_add: errorCatching convertMathUtility orig_map
		ai_subtract: errorCatching convertMathUtility orig_map
		ai_multiply: errorCatching convertMathUtility orig_map
		ai_divide: errorCatching convertMathUtility orig_map
		ai_max: errorCatching convertMathUtility orig_map
		ai_min: errorCatching convertMathUtility orig_map
		ai_pow: errorCatching convertMathUtility orig_map
		ai_normalize: errorCatching convertMathUtility orig_map
		ai_atan: errorCatching convertMathUtility orig_map
		ai_cross: errorCatching convertMathUtility orig_map
		ai_abs: errorCatching convertAiAbs orig_map
		ai_dot: errorCatching convertMathUtility orig_map
		ai_bump2d: errorCatching convertAiBump2d orig_map
		ai_bump3d: errorCatching convertAiBump3d orig_map
		ai_normal_map: errorCatching convertAiNormalMap orig_map
		ai_vector_map: errorCatching convertAiVectorMap orig_map
		ai_exp: errorCatching convertAiExp orig_map

		--following utilies will be replaced with default rpr arithmetic node, will be supported later
		ai_round_corners: errorCatching convertUnsupportedUtility orig_map
		ai_color_convert: errorCatching convertUnsupportedUtility orig_map
		ai_color_correct: errorCatching convertUnsupportedUtility orig_map
		ai_color_jitter: errorCatching convertUnsupportedUtility orig_map
		ai_float_to_int: errorCatching convertUnsupportedUtility orig_map
		ai_float_to_matrix: errorCatching convertUnsupportedUtility orig_map
		ai_float_to_rgb: errorCatching convertUnsupportedUtility orig_map
		ai_float_to_rgba: errorCatching convertUnsupportedUtility orig_map
		ai_rgb_to_float: errorCatching convertUnsupportedUtility orig_map
		ai_rgba_to_float: errorCatching convertUnsupportedUtility orig_map
		ai_rgb_to_vector: errorCatching convertUnsupportedUtility orig_map
		ai_shuffle: errorCatching convertUnsupportedUtility orig_map
		ai_vector_to_rgb: errorCatching convertUnsupportedUtility orig_map
		ai_physical_sky: errorCatching convertUnsupportedUtility orig_map
		ai_compare: errorCatching convertUnsupportedUtility orig_map
		ai_complement: errorCatching convertUnsupportedUtility orig_map
		ai_fraction: errorCatching convertUnsupportedUtility orig_map
		ai_is_finite: errorCatching convertUnsupportedUtility orig_map
		ai_length: errorCatching convertUnsupportedUtility orig_map
		ai_log: errorCatching convertUnsupportedUtility orig_map
		ai_matrix_transform: errorCatching convertUnsupportedUtility orig_map
		ai_matrix_multiply_vector: errorCatching convertUnsupportedUtility orig_map
		ai_mix_rgba: errorCatching convertUnsupportedUtility orig_map	
		ai_negate: errorCatching convertUnsupportedUtility orig_map
		ai_modulo: errorCatching convertUnsupportedUtility orig_map
		ai_random: errorCatching convertUnsupportedUtility orig_map
		ai_range: errorCatching convertUnsupportedUtility orig_map
		ai_reciprocal: errorCatching convertUnsupportedUtility orig_map
		ai_sign: errorCatching convertUnsupportedUtility orig_map
		ai_space_transform: errorCatching convertUnsupportedUtility orig_map
		ai_sqrt: errorCatching convertUnsupportedUtility orig_map
		ai_trigo: errorCatching convertUnsupportedUtility orig_map
		ai_state_float: errorCatching convertUnsupportedUtility orig_map
		ai_state_int: errorCatching convertUnsupportedUtility orig_map
		ai_state_vector: errorCatching convertUnsupportedUtility orig_map
		ai_ambient_occlusion: errorCatching convertUnsupportedUtility orig_map
		ai_complex_ior: errorCatching convertUnsupportedUtility orig_map
		ai_shadow_matte: errorCatching convertUnsupportedUtility orig_map
		ai_flakes: errorCatching convertUnsupportedUtility orig_map
		ai_toon: errorCatching convertUnsupportedUtility orig_map
		ai_noise: errorCatching convertUnsupportedUtility orig_map
		ai_camera_projection: errorCatching convertUnsupportedUtility orig_map
		ai_cell_noise: errorCatching convertUnsupportedUtility orig_map
		ai_checkerboard: errorCatching convertUnsupportedUtility orig_map
		ai_image: errorCatching convertUnsupportedUtility orig_map
		ai_layer_rgba: errorCatching convertUnsupportedUtility orig_map
		ai_layer_float: errorCatching convertUnsupportedUtility orig_map
		ai_ramp_rgb: errorCatching convertUnsupportedUtility orig_map
		ai_ramp_float: errorCatching convertUnsupportedUtility orig_map
		ai_triplanar: errorCatching convertUnsupportedUtility orig_map
		ai_user_data_rgb: errorCatching convertUnsupportedUtility orig_map
		ai_user_data_rgba: errorCatching convertUnsupportedUtility orig_map
		ai_user_data_float: errorCatching convertUnsupportedUtility orig_map
		ai_user_data_int: errorCatching convertUnsupportedUtility orig_map
		ai_user_data_string: errorCatching convertUnsupportedUtility orig_map
		ai_blackbody: errorCatching convertUnsupportedUtility orig_map
		ai_cache: errorCatching convertUnsupportedUtility orig_map
		ai_clamp: errorCatching convertUnsupportedUtility orig_map
		ai_curvature: errorCatching convertUnsupportedUtility orig_map
		ai_facing_ratio: errorCatching convertUnsupportedUtility orig_map
		ai_flat: errorCatching convertUnsupportedUtility orig_map
		ai_motion_vector: errorCatching convertUnsupportedUtility orig_map
		ai_ray_switch_rgba: errorCatching convertUnsupportedUtility orig_map
		ai_switch_rgba: errorCatching convertUnsupportedUtility orig_map
		ai_utility: errorCatching convertUnsupportedUtility orig_map
		ai_uv_projection: errorCatching convertUnsupportedUtility orig_map
		ai_uv_transform: errorCatching convertUnsupportedUtility orig_map
		ai_wireframe: errorCatching convertUnsupportedUtility orig_map
		ai_volume_sample_float: errorCatching convertUnsupportedUtility orig_map
		ai_volume_sample_rgb: errorCatching convertUnsupportedUtility orig_map
		ai_cryptomatte: errorCatching convertUnsupportedUtility orig_map
		
		default: orig_map
	)
	
	if new_map!=orig_map then ( 		-- if converted, add to the list of converted materials
		append orig_maps orig_map
		append new_maps new_map
	)
	new_map
)

fn convertMaterial orig_mtl =(
		
	local i=findItem orig_mtls orig_mtl -- check if we have already converted this material
	if i>0 then return new_mtls[i]  --if yes, just return the already converted one	
	
	-- recurse into sub-materials, if any
	local sub_count_mtl=getNumSubMtls orig_mtl
	if sub_count_mtl >= 1 then (
		for mat=1 to sub_count_mtl do (
			subMtl = getSubMtl orig_mtl mat
			if subMtl != undefined do (
				setSubMtl orig_mtl mat (convertMaterial subMtl)
			)
		)
	)

	local sub_count_map=getNumSubTexmaps orig_mtl
	if sub_count_map >= 1 then (
		for mp=1 to sub_count_map do (
			newMap = convertUtility (getSubTexmap orig_mtl mp)
			setSubTexmap orig_mtl mp newMap
		)
	)
	
	cls=classof orig_mtl
	local new_mtl=case cls of (
		ai_standard_surface: errorCatching convertAiStandardSurface orig_mtl
		ai_layer_shader: errorCatching convertAiLayerShader orig_mtl
		ai_car_paint: errorCatching convertAiCarPaint orig_mtl
		 
		--following materials will be replaced with default green rpr uber mat, will be supported later
		ai_lambert: errorCatching convertUnsupportedMtl orig_mtl 
		ai_matte: errorCatching convertUnsupportedMtl orig_mtl 
		ai_standard_hair: errorCatching convertUnsupportedMtl orig_mtl 
		ai_two_sided: errorCatching convertUnsupportedMtl orig_mtl 
		ArnoldMapToMtl: errorCatching convertUnsupportedMtl orig_mtl 
		ai_passthrough: errorCatching convertUnsupportedMtl orig_mtl 
		ai_ray_switch_shader: errorCatching convertUnsupportedMtl orig_mtl
		ai_switch_shader: errorCatching convertUnsupportedMtl orig_mtl 
		ai_trace_set: errorCatching convertUnsupportedMtl orig_mtl 
		ai_standard_volume: errorCatching convertUnsupportedMtl orig_mtl 
		ai_mix_shader: errorCatching convertUnsupportedMtl orig_mtl 
		ai_atmosphere_volume: errorCatching convertUnsupportedMtl orig_mtl 
		ai_fog: errorCatching convertUnsupportedMtl orig_mtl 
		ai_aov_write_float: errorCatching convertUnsupportedMtl orig_mtl 
		ai_aov_write_int: errorCatching convertUnsupportedMtl orig_mtl 
		ai_aov_write_rgb: errorCatching convertUnsupportedMtl orig_mtl 
		ai_aov_write_rgba: errorCatching convertUnsupportedMtl orig_mtl
		
		default: orig_mtl
	)
	
	if new_mtl != orig_mtl then ( 		-- if converted, add to the list of converted materials
		append orig_mtls orig_mtl
		append new_mtls new_mtl
	)
	
	new_mtl
)

fn cleanUpConversionData =(

	delete (for elem in new_lights where (superclassof elem == light) and isvalidnode elem collect elem) 

	-- delete AOVs
	re = maxOps.GetCurRenderElementMgr()
    re.removeallrenderelements()

    orig_shps=#()
    new_shps=#()
	orig_mtls=#()
	new_mtls=#()
	orig_maps=#()
	new_maps=#()
	orig_lights=#()
	new_lights=#()
	orig_cameras=#()
	new_cameras=#()
	
	clearUndoBuffer()
	true
)

fn convertScene =(
	
	start = timeStamp()

	-- material conversion
	aiMtlClasses = #("ai_standard_surface", "ai_car_paint", "ai_lambert", "ai_layer_shader", "ai_matte", \
		"ai_standard_hair", "ai_two_sided", "ArnoldMapToMtl", "ai_passthrough", "ai_ray_switch_shader", "ai_switch_shader", \
		"ai_trace_set", "ai_standard_volume", "ai_mix_shader", "ai_atmosphere_volume", "ai_fog", "ai_aov_write_float", "ai_aov_write_int", \
		"ai_aov_write_rgb", "ai_aov_write_rgba")


	for c in aiMtlClasses do ( --where c.creatable 
		cls = execute c
		if classof cls == material do(
			-- get all materials from scene
			clssInst = getclassinstances cls
			for i in clssInst do(
				newMat = errorCatching convertMaterial i
				if newMat != "no_replace" do (
					replaceInstances i newMat
				)
			)
		)
	)
	
	aiMapClasses = #("OSLMap", "ai_bump2d", "ai_bump3d", "ai_normal_map", "ai_round_corners", "ai_color_convert", "ai_color_correct", 
		"ai_color_jitter", "ai_float_to_int", "ai_float_to_matrix", "ai_float_to_rgb", "ai_float_to_rgba", "ai_rgb_to_float", "ai_rgba_to_float", 
		"ai_rgb_to_vector", "ai_shuffle", "ai_vector_map", "ai_vector_to_rgb", "ai_physical_sky", "ai_abs", "ai_add", "ai_atan", "ai_compare", 
		"ai_complement", "ai_dot", "ai_divide", "ai_cross", "ai_exp", "ai_fraction", "ai_is_finite", "ai_length", "ai_log", "ai_matrix_transform", 
		"ai_matrix_multiply_vector", "ai_max", "ai_min", "ai_mix_rgba", "ai_multiply", "ai_negate", "ai_modulo", "ai_normalize", "ai_pow", "ai_random",
		"ai_range", "ai_reciprocal", "ai_sign", "ai_space_transform", "ai_sqrt", "ai_trigo", "ai_subtract", "ai_state_float", "ai_state_int", 
		"ai_state_vector", "ai_ambient_occlusion", "ai_complex_ior", "ai_shadow_matte", "ai_flakes", "ai_toon", "ai_noise", "ai_camera_projection",
		"ai_cell_noise", "ai_checkerboard", "ai_image", "ai_layer_rgba", "ai_layer_float", "ai_ramp_rgb", "ai_ramp_float", "ai_triplanar",
		"ai_user_data_rgba", "ai_user_data_rgb", "ai_user_data_float", "ai_user_data_int", "ai_user_data_string",
		"ai_blackbody", "ai_cache", "ai_clamp", "ai_curvature", "ai_facing_ratio", "ai_flat", "ai_motion_vector", "ai_ray_switch_rgba",
		"ai_switch_rgba", "ai_utility", "ai_uv_projection", "ai_uv_transform", "ai_wireframe", "ai_volume_sample_float", "ai_volume_sample_rgb",
		"ai_cryptomatte")

	-- map conversion
	for c in aiMapClasses do(
		cls = execute c
		if classof cls == textureMap do(
			classInst = getclassinstances cls
			for i in classInst do(
				newMap = errorCatching convertUtility i
				replaceInstances i newMap
			)
		)
	)

	-- light conversion
	allLights = for o in objects where superclassof o == light and o.category == #Arnold collect o
	for i in allLights do(
		newLight = convertLight i
		if newLight != "no_replace" do (
			replaceInstances i newLight
		)
	)

	end = timeStamp()
	print("Scene conversion took " +  ((end - start) / 1000.0) as string + " seconds ")
	print("Converted: " + new_mtls.count as string + " materials, " + new_maps.count as string + " utilities and " + new_lights.count as string + " lights.")

	renderers.current = Radeon_ProRender()
	renderers.current.raycastEpsilon = 0.001
	renderers.current.texturecompression = true

	cleanUpConversionData()
	
)

if not globalVars.isglobal(#autoLaunch) do (
     convertScene()
)

