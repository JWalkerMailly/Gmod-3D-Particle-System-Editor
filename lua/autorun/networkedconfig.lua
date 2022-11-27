
-- This is only used internally by the configuration module. Configs
-- are JSON files and since we can't store function references, we need
-- to setup a lookup table and manually do the conversions.
GlobalMathFunctionsConversionTable = {
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

function DeserializeParticles(weapon)

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

	local particles = util.JSONToTable(data);
	if (particles == nil) then
		return {};
	end

	return particles;
end

function ParseParticles(weapon)

	local particles = DeserializeParticles(weapon);
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

		-- Convert each string representation to its actual function counterpart.
		v.RotationFunction 		= GlobalMathFunctionsConversionTable[v.RotationFunction];
		v.ColorFunction 		= GlobalMathFunctionsConversionTable[v.ColorFunction];
		v.AlphaFunction 		= GlobalMathFunctionsConversionTable[v.AlphaFunction];
		v.ScaleFunction 		= GlobalMathFunctionsConversionTable[v.ScaleFunction];
	end

	PrintTable(particles)

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
		system:InitializeParticles(ParseParticles(weapon));

		--PrintTable(weapon.Particles);

/*
		-- Parse update message to proper entities.
		local system = net.ReadEntity();
		if (system == NULL || system == nil || !system:IsValid() || system:GetClass() != "3d_particle_system") then
			return;
		end

		-- Convert editor functions to actual lua functions for the particle system.
		local particles = util.JSONToTable(net.ReadString());
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

			-- Convert each string representation to its actual function counterpart.
			v.RotationFunction 		= GlobalMathFunctionsConversionTable[v.RotationFunction];
			v.ColorFunction 		= GlobalMathFunctionsConversionTable[v.ColorFunction];
			v.AlphaFunction 		= GlobalMathFunctionsConversionTable[v.AlphaFunction];
			v.ScaleFunction 		= GlobalMathFunctionsConversionTable[v.ScaleFunction];
		end

		-- Upload configuration file to system.
		system:InitializeParticles(particles);*/
	end);
end