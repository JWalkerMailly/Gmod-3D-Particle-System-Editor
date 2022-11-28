
GLOBALS_3D_PARTICLE_EDITOR = {};

-- This is only used internally by the configuration module. Configs
-- are JSON files and since we can't store function references, we need
-- to setup a lookup table and manually do the conversions.
GLOBALS_3D_PARTICLE_EDITOR.MathFunctionsConversionTable = {
	["Sine"] 			= math.sin,
	["Cosine"] 			= math.cos,
	["Tangent"] 		= math.tan,
	["InBack"] 			= math.ease.InBack,
	["InBounce"] 		= math.ease.InBounce,
	["InCirc"] 			= math.ease.InCirc,
	["InCubic"] 		= math.ease.InCubic,
	["InElastic"] 		= math.ease.InElastic,
	["InExpo"] 			= math.ease.InExpo,
	["InOutBack"] 		= math.ease.InOutBack,
	["InOutBounce"] 	= math.ease.InOutBounce,
	["InOutCirc"] 		= math.ease.InOutCirc,
	["InOutCubic"] 		= math.ease.InOutCubic,
	["InOutElastic"] 	= math.ease.InOutElastic,
	["InOutExpo"] 		= math.ease.InOutExpo,
	["InOutQuad"] 		= math.ease.InOutQuad,
	["InOutQuart"] 		= math.ease.InOutQuart,
	["InOutQuint"] 		= math.ease.InOutQuint,
	["InOutSine"] 		= math.ease.InOutSine,
	["InQuad"] 			= math.ease.InQuad,
	["InQuart"] 		= math.ease.InQuart,
	["InQuint"] 		= math.ease.InQuint,
	["InSine"] 			= math.ease.InSine,
	["OutBack"] 		= math.ease.OutBack,
	["OutBounce"] 		= math.ease.OutBounce,
	["OutCirc"] 		= math.ease.OutCirc,
	["OutCubic"] 		= math.ease.OutCubic,
	["OutElastic"] 		= math.ease.OutElastic,
	["OutExpo"] 		= math.ease.OutExpo,
	["OutQuad"] 		= math.ease.OutQuad,
	["OutQuart"] 		= math.ease.OutQuart,
	["OutQuint"] 		= math.ease.OutQuint,
	["OutSine"] 		= math.ease.OutSine
};

-- Used to parse strings.
function GLOBALS_3D_PARTICLE_EDITOR:ToGeneric(data)
	return "\"" .. data .. "\"";
end

-- Used to parse integers and floats.
function GLOBALS_3D_PARTICLE_EDITOR:ToNumber(data)
	return data;
end

-- Used to parse angles.
function GLOBALS_3D_PARTICLE_EDITOR:ToAngle(data)
	return "\"{" .. data.p .. " " .. data.y .. " " .. data.r .. "}\"";
end

-- Used to parse vectors.
function GLOBALS_3D_PARTICLE_EDITOR:ToVector(data)
	return "\"[" .. data.x .. " " .. data.y .. " " .. data.z .. "]\"";
end

-- Used to parse colors.
function GLOBALS_3D_PARTICLE_EDITOR:ToColor(data)
	return "{\"r\":" .. data[1] .. ",\"g\":" .. data[2] .. ",\"b\":" .. data[3] .. ",\"a\":255}";
end

-- Used to parse colors.
function GLOBALS_3D_PARTICLE_EDITOR:ToVectorColor(data)
	return "{\"r\":" .. data.r .. ",\"g\":" .. data.g .. ",\"b\":" .. data.b .. ",\"a\":255}";
end

function GLOBALS_3D_PARTICLE_EDITOR:SerializeParticles(weapon)

	local data = "{";
	for k,v in pairs(weapon.Particles) do

		data = data .. "\"" .. k .. "\":{";
		for x,y in pairs(weapon.Particles[k]) do
			data = data .. "\"" .. x .. "\":" .. tostring(y) .. ",";
		end

		data = data:sub(1, -2);
		data = data .. "},";
	end

	data = data:sub(1, -2);
	data = data .. "}";
	return data;
end

function GLOBALS_3D_PARTICLE_EDITOR:DeserializeParticlesToSource(data)

	local particles = util.JSONToTable(data);
	if (particles == nil) then
		return {};
	end

	return particles;
end

function GLOBALS_3D_PARTICLE_EDITOR:DeserializeParticlesToEditor(config)

	-- Convert JSON config file format to usable types.
	local particles = self:DeserializeParticlesToSource(config);

	-- Convert types to editor types.
	for k,v in pairs(particles) do
		for x,y in pairs(v) do
			if (isstring(y)) then particles[k][x] = self:ToGeneric(y); continue; end
			if (isnumber(y)) then particles[k][x] = self:ToNumber(y); continue; end
			if (isangle(y))  then particles[k][x] = self:ToAngle(y); continue; end
			if (isvector(y)) then particles[k][x] = self:ToVector(y); continue; end
			if (isbool(y)) then continue; end
			particles[k][x] = self:ToVectorColor(y);
		end
	end

	return particles;
end

if (SERVER) then
	util.AddNetworkString("3d_particle_system_upload_config");
end

if (CLIENT) then

	-- Update a particle system's configuration from the network.
	-- The maximum allowed string length for net messages is 65532 characters.
	net.Receive("3d_particle_system_upload_config", function(len)

		local weapon = net.ReadEntity();
		local system = net.ReadEntity();

		-- Upload configuration file to system.
		local data = GLOBALS_3D_PARTICLE_EDITOR:SerializeParticles(weapon);
		local particles = GLOBALS_3D_PARTICLE_EDITOR:DeserializeParticlesToSource(data);
		for k,v in pairs(particles) do

			-- Since JSON and DPropertyLists can't handle nil or empty values,
			-- nil states must be handled manually according to the desired behavior.
			if (v.InheritPos) 		then v.Pos 			= nil; end
			if (v.InheritLifeTime) 	then v.LifeTime 	= nil; end
			if (!v.UseEndRotation) 	then v.EndRotation 	= nil; end
			if (!v.UseEndColor) 	then v.EndColor 	= nil; end
			if (!v.UseEndAlpha) 	then v.EndAlpha 	= nil; end
			if (!v.UseScaleAxis) 	then v.ScaleAxis 	= Vector(0, 0, 0); end
			if (!v.UseEndScale) 	then v.EndScale 	= nil; end
			if (v.Material != "")	then v.Material 	= Material(v.Material);
			else 						 v.Material 	= nil; end

			-- Convert each string representation to its actual function counterpart.
			v.RotationFunction 		= GLOBALS_3D_PARTICLE_EDITOR.MathFunctionsConversionTable[v.RotationFunction];
			v.ColorFunction 		= GLOBALS_3D_PARTICLE_EDITOR.MathFunctionsConversionTable[v.ColorFunction];
			v.AlphaFunction 		= GLOBALS_3D_PARTICLE_EDITOR.MathFunctionsConversionTable[v.AlphaFunction];
			v.ScaleFunction 		= GLOBALS_3D_PARTICLE_EDITOR.MathFunctionsConversionTable[v.ScaleFunction];
		end

		system:InitializeParticles(particles);
	end);
end