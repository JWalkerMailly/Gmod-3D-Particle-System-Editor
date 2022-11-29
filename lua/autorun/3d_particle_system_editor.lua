
-- This behaves like a static class.
GLOBALS_3D_PARTICLE_EDITOR = {};

-- This is only used internally by the configuration module. Configs
-- are JSON files and since we can't store function references, we need
-- to setup a lookup table and manually do the conversions afterwards.
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

function GLOBALS_3D_PARTICLE_EDITOR:SerializeParticles(worker)

	local data = "{";
	for k,v in pairs(worker.Particles) do

		data = data .. "\"" .. k .. "\":{";
		for x,y in pairs(worker.Particles[k]) do
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

	-- If conversion fails, return empty table to avoid breaking the editor.
	local particles = util.JSONToTable(data);
	if (particles == nil) then
		return {};
	end

	return particles;
end

function GLOBALS_3D_PARTICLE_EDITOR:DeserializeParticles(config, worker)

	-- Convert JSON config file datatypes to source datatypes.
	local particles = self:DeserializeParticlesToSource(config);

	-- Convert source datatypes to editor datatypes.
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

	-- If a worker is suppplied, apply deserialized particles to it.
	if (worker != nil) then
		worker.Particles = particles;
	end

	return particles;
end

function GLOBALS_3D_PARTICLE_EDITOR:ParseConfiguration(config)

	local particles = GLOBALS_3D_PARTICLE_EDITOR:DeserializeParticlesToSource(config);
	for k,v in pairs(particles) do

		-- Since JSON and DPropertyLists can't handle nil or empty values,
		-- nil states must be handled manually according to the desired behavior.
		if (v.InheritPos) 		then v.Pos 			= nil; end
		if (v.InheritAngles) 	then v.Angles		= nil; end
		if (v.InheritLifeTime) 	then v.LifeTime 	= nil; end
		if (!v.UseEndRotation) 	then v.EndRotation 	= nil; end
		if (!v.UseEndColor) 	then v.EndColor 	= nil; end
		if (!v.UseEndAlpha) 	then v.EndAlpha 	= nil; end
		if (!v.UseEndScale) 	then v.EndScale 	= nil; end
		if (!v.UseEndAxisScale) then v.EndAxisScale = nil; end
		if (v.Material != "")	then v.Material 	= Material(v.Material);
		else 						 v.Material 	= nil; end

		-- Convert each string representation to its actual math function counterpart.
		v.RotationFunction 	= GLOBALS_3D_PARTICLE_EDITOR.MathFunctionsConversionTable[v.RotationFunction];
		v.ColorFunction 	= GLOBALS_3D_PARTICLE_EDITOR.MathFunctionsConversionTable[v.ColorFunction];
		v.AlphaFunction 	= GLOBALS_3D_PARTICLE_EDITOR.MathFunctionsConversionTable[v.AlphaFunction];
		v.ScaleFunction 	= GLOBALS_3D_PARTICLE_EDITOR.MathFunctionsConversionTable[v.ScaleFunction];
		v.AxisScaleFunction = GLOBALS_3D_PARTICLE_EDITOR.MathFunctionsConversionTable[v.AxisScaleFunction];
	end

	return particles;
end

function GLOBALS_3D_PARTICLE_EDITOR:SetParticlePropertyValue(worker, particle, prop, type, value)

	-- Vector color is a special case. We handle JSON serialization manually since its data
	-- structure is unique and differs from vectors and angles.
	if (type == "VectorColor") then
		worker.Particles[particle:GetText()][prop] = GLOBALS_3D_PARTICLE_EDITOR:ToColor(value);
		return;
	end

	-- Add surrounding quotes to lua string datatype ("example") in order to be a JSON datatype (""example"").
	if (type == "Generic" || type == "Combo") then
		worker.Particles[particle:GetText()][prop] = GLOBALS_3D_PARTICLE_EDITOR:ToGeneric(value);
		return;
	end

	worker.Particles[particle:GetText()][prop] = value;
end

function GLOBALS_3D_PARTICLE_EDITOR:GetPropertyDefault(worker, particle, prop, type, fallback)

	-- Determine if the worker already contains a configuration file.
	local property = worker.Particles[particle:GetText()][prop];
	if (property != nil) then

		-- Convert JSON color datatype to a lua Vector datatype.
		if (type == "VectorColor") then
			local color = util.JSONToTable(property);
			return Vector(color.r, color.g, color.b);
		end

		-- Remove surrounding quotes from JSON string datatype (""example"") for lua string datatype ("example"). 
		if (type == "Generic" || type == "Combo") then
			return string.sub(property, 2, -2);
		end
	end

	-- If the property is nil, or we are not using a configuration file,
	-- this will default to using the supplied fallback value.
	return property || fallback;
end

function GLOBALS_3D_PARTICLE_EDITOR:AddParticlePropertyRow(worker, panel, particle, prop, category, name, type, settings, choices, default, useConfig)

	-- Get the default value either form the worker, or the fallback. If we are using a configuration
	-- file, the worker will already have all its properties loaded. We'll transform the value for the editor.
	local defaultValue = self:GetPropertyDefault(worker, particle, prop, type, default);

	-- If we are not using a configuration file, load the fallback value onto the worker.
	if (!useConfig) then self:SetParticlePropertyValue(worker, particle, prop, type, defaultValue); end

	-- Create property editor.
	local editor = panel:CreateRow(category, name);
	editor:Setup(type, settings);
	editor.DataChanged = function(_, val)

		-- For some reason, DPropertyLists use 1 and 0 for their boolean datatype.
		if (type == "Boolean") then
			if (val == 1) then self:SetParticlePropertyValue(worker, particle, prop, type, true);
			else self:SetParticlePropertyValue(worker, particle, prop, type, false); end
			return;
		end

		-- Convert Source color datatype to a lua Vector datatype.
		if (type == "VectorColor") then
			local color = string.Split(val, " ");
			self:SetParticlePropertyValue(worker, particle, prop, type, Vector(color[1] * 255, color[2] * 255, color[3] * 255));
			return;
		end

		self:SetParticlePropertyValue(worker, particle, prop, type, val);
	end

	-- Choices are used by Combo boxes.
	if (choices != nil) then
		for k,v in pairs(choices) do
			editor:AddChoice(k, k);
		end
	end

	-- Set default value after initialization.
	if (defaultValue != nil) then editor:SetValue(defaultValue); end
end

function GLOBALS_3D_PARTICLE_EDITOR:AddParticlePropertyPanel(worker, panel, dtextentry, useConfig)

	-- Prepare worker particles if not already done.
	if (worker.Particles == nil) then
		worker.Particles = {};
	end

	-- Do nothing if the particle we are trying to create already exists on the worker.
	-- If we are creating this panel from a configuration file, resume execution.
	if (worker.Particles[dtextentry:GetValue()] != nil && !useConfig) then
		worker:GetOwner():PrintMessage(HUD_PRINTTALK, "A particle with this name already exists in the system.");
		return;
	end

	-- Initialize particle array for editor key values.
	if (!useConfig) then worker.Particles[dtextentry:GetValue()] = {}; end

	-- Particle collapsible category, this will be added onto the panel argument.
	local category = vgui.Create("DCollapsibleCategory");
	category:SetLabel(dtextentry:GetValue());
	category:SetExpanded(false);
	panel:AddItem(category);

		-- Generic label. This will be hidden and contain the key of the particle.
		-- The instance will be used as a pass by reference pointer when renaming
		-- particles in the system using the editor.
		local label = vgui.Create("DLabel", category);
		label:SetText(dtextentry:GetValue());
		label:SetHeight(0);
		label:SetAlpha(0);
		label:Dock(TOP);

		-- Rename particle button.
		local rename = vgui.Create("DButton", category);
		rename:SetText("Rename");
		rename:Dock(TOP);
		function rename:DoClick()

			-- Do nothing if we are renaming the particle to one that already exists.
			local newKey = dtextentry:GetValue();
			if (worker.Particles[newKey] != nil) then
				worker:GetOwner():PrintMessage(HUD_PRINTTALK, "A particle with this name already exists in the system.");
				return;
			end

			-- Copy data over and delete old key references.
			local oldKey = label:GetText();
			worker.Particles[newKey] = worker.Particles[oldKey];
			worker.Particles[oldKey] = nil;
			category:SetLabel(newKey);
			label:SetText(newKey);
		end

		-- Remove button.
		local delete = vgui.Create("DButton", category);
		delete:SetText("Delete");
		delete:Dock(TOP);
		function delete:DoClick()

			-- Delete entries to the particles properties array.
			local oldKey = label:GetText();
			worker.Particles[oldKey] = nil;
			category:Remove();
		end

		-- Generic panel for layout.
		local container = vgui.Create("DPanel", category);
		container:Dock(TOP);
		category:SetContents(container);

			-- Particle properties list.
			local particleProps = vgui.Create("DProperties", container);
			particleProps:SetHeight(1010);
			particleProps:Dock(TOP);

				-- Rendering properties.
				local model = "models/hunter/misc/sphere075x075.mdl";
				local material = "models/props_combine/portalball001_sheet";
				self:AddParticlePropertyRow(worker, particleProps, label, "Model", 				"Rendering", "Model", 				"Generic", 		{}, nil, model, useConfig);
				self:AddParticlePropertyRow(worker, particleProps, label, "Skin", 				"Rendering", "Skin", 				"Int", 			{ min = 0, max = 100 }, nil, 0, useConfig);
				self:AddParticlePropertyRow(worker, particleProps, label, "BodyGroups", 		"Rendering", "Body Groups", 		"Generic", 		{}, nil, "0", useConfig);
				self:AddParticlePropertyRow(worker, particleProps, label, "Material", 			"Rendering", "Material", 			"Generic", 		{}, nil, material, useConfig);

				-- Transform properties.
				self:AddParticlePropertyRow(worker, particleProps, label, "InheritPos", 		"Transform", "Inherit Pos", 		"Boolean", 		{}, nil, true, useConfig);
				self:AddParticlePropertyRow(worker, particleProps, label, "Pos", 				"Transform", "Position", 			"Generic", 		{}, nil, "[0 0 0]", useConfig);
				self:AddParticlePropertyRow(worker, particleProps, label, "LocalPos", 			"Transform", "Local Position", 		"Generic", 		{}, nil, "[0 0 0]", useConfig);
				self:AddParticlePropertyRow(worker, particleProps, label, "InheritAngles", 		"Transform", "Inherit Angles", 		"Boolean", 		{}, nil, false, useConfig);
				self:AddParticlePropertyRow(worker, particleProps, label, "Angles", 			"Transform", "Angles", 				"Generic", 		{}, nil, "{0 0 0}", useConfig);

				-- Timing properties.
				self:AddParticlePropertyRow(worker, particleProps, label, "Delay", 				"Timing", "Delay", 					"Float", 		{ min = 0, max = 60 }, nil, 0, useConfig);
				self:AddParticlePropertyRow(worker, particleProps, label, "InheritLifeTime", 	"Timing", "Inherit Life Time", 		"Boolean", 		{}, nil, false, useConfig);
				self:AddParticlePropertyRow(worker, particleProps, label, "LifeTime", 			"Timing", "Life Time", 				"Float", 		{ min = 0, max = 60 * 5 }, nil, 1, useConfig);
				self:AddParticlePropertyRow(worker, particleProps, label, "Looping", 			"Timing", "Looping", 				"Boolean", 		{}, nil, false, useConfig);

				-- Rotation properties.
				self:AddParticlePropertyRow(worker, particleProps, label, "RotationFunction", 	"Rotation", "Function", 			"Combo", 		{}, self.MathFunctionsConversionTable, "Sine", useConfig);
				self:AddParticlePropertyRow(worker, particleProps, label, "RotationNormal", 	"Rotation", "Rotation Normal", 		"Generic", 		{}, nil, "[0 0 0]", useConfig);
				self:AddParticlePropertyRow(worker, particleProps, label, "RotateAroundNormal", "Rotation", "Rotate Around Normal", "Boolean", 		{}, nil, true, useConfig);
				self:AddParticlePropertyRow(worker, particleProps, label, "StartRotation", 		"Rotation", "Start Rotation", 		"Float", 		{ min = -360000, max = 360000 }, nil, 0, useConfig);
				self:AddParticlePropertyRow(worker, particleProps, label, "UseEndRotation", 	"Rotation", "Use End Rotation", 	"Boolean", 		{}, nil, false, useConfig);
				self:AddParticlePropertyRow(worker, particleProps, label, "EndRotation", 		"Rotation", "End Rotation", 		"Float", 		{ min = -360000, max = 360000 }, nil, 0, useConfig);
				self:AddParticlePropertyRow(worker, particleProps, label, "RotationFunctionMod","Rotation", "Rotation Rate", 		"Float", 		{ min = -360000, max = 360000 }, nil, 1, useConfig);

				-- Color properties.
				self:AddParticlePropertyRow(worker, particleProps, label, "ColorFunction", 		"Color", "Function", 				"Combo", 		{}, self.MathFunctionsConversionTable, "Sine", useConfig);
				self:AddParticlePropertyRow(worker, particleProps, label, "StartColor", 		"Color", "Start Color", 			"VectorColor", 	{}, nil, Vector(255, 255, 255), useConfig);
				self:AddParticlePropertyRow(worker, particleProps, label, "UseEndColor", 		"Color", "Use End Color", 			"Boolean", 		{}, nil, false, useConfig);
				self:AddParticlePropertyRow(worker, particleProps, label, "EndColor", 			"Color", "End Color", 				"VectorColor", 	{}, nil, Vector(255, 255, 255), useConfig);
				self:AddParticlePropertyRow(worker, particleProps, label, "ColorFunctionMod", 	"Color", "Color Rate", 				"Float", 		{ min = -360000, max = 360000 }, nil, 1, useConfig);

				-- Alpha properties.
				self:AddParticlePropertyRow(worker, particleProps, label, "AlphaFunction", 		"Alpha", "Function", 				"Combo", 		{}, self.MathFunctionsConversionTable, "Sine", useConfig);
				self:AddParticlePropertyRow(worker, particleProps, label, "StartAlpha", 		"Alpha", "Start Alpha", 			"Float", 		{ min = 0, max = 255 }, nil, 255, useConfig);
				self:AddParticlePropertyRow(worker, particleProps, label, "UseEndAlpha", 		"Alpha", "Use End Alpha", 			"Boolean", 		{}, nil, false, useConfig);
				self:AddParticlePropertyRow(worker, particleProps, label, "EndAlpha", 			"Alpha", "End Alpha", 				"Float", 		{ min = 0, max = 255 }, nil, 0, useConfig);
				self:AddParticlePropertyRow(worker, particleProps, label, "AlphaFunctionMod", 	"Alpha", "Alpha Rate", 				"Float", 		{ min = -360000, max = 360000 }, nil, 1, useConfig);

				-- Scale properties.
				self:AddParticlePropertyRow(worker, particleProps, label, "ScaleFunction", 		"Scale", "Function", 				"Combo", 		{}, self.MathFunctionsConversionTable, "Sine", useConfig);
				self:AddParticlePropertyRow(worker, particleProps, label, "StartScale", 		"Scale", "Start Scale", 			"Float", 		{ min = 0, max = 360000 }, nil, 1, useConfig);
				self:AddParticlePropertyRow(worker, particleProps, label, "UseEndScale", 		"Scale", "Use End Scale", 			"Boolean", 		{}, nil, false, useConfig);
				self:AddParticlePropertyRow(worker, particleProps, label, "EndScale", 			"Scale", "End Scale", 				"Float", 		{ min = 0, max = 360000 }, nil, 0, useConfig);
				self:AddParticlePropertyRow(worker, particleProps, label, "ScaleFunctionMod", 	"Scale", "Scale Rate", 				"Float", 		{ min = -360000, max = 360000 }, nil, 1, useConfig);

				-- Axis scale properties.
				self:AddParticlePropertyRow(worker, particleProps, label, "AxisScaleFunction", 	"Axis", "Function", 				"Combo", 		{}, self.MathFunctionsConversionTable, "Sine", useConfig);
				self:AddParticlePropertyRow(worker, particleProps, label, "StartAxisScale", 	"Axis", "Start Axis Scaling", 		"Generic", 		{}, nil, "[1 1 1]", useConfig);
				self:AddParticlePropertyRow(worker, particleProps, label, "UseEndAxisScale", 	"Axis", "Use End Axis Scaling",		"Boolean", 		{}, nil, false, useConfig);
				self:AddParticlePropertyRow(worker, particleProps, label, "EndAxisScale", 		"Axis", "End Axis Scaling", 		"Generic", 		{}, nil, "[0 0 0]", useConfig);
				self:AddParticlePropertyRow(worker, particleProps, label, "AxisScaleFunctionMod","Axis","Axis Scale Rate", 			"Float", 		{ min = -360000, max = 360000 }, nil, 1, useConfig);
end

if (SERVER) then
	util.AddNetworkString("3d_particle_system_upload_config");
end

if (CLIENT) then

	-- Update a particle system's configuration from the network.
	-- The maximum allowed string length for net messages is 65532 characters.
	-- This will transfer the data from the worker onto the particle system entity.
	net.Receive("3d_particle_system_upload_config", function(len)

		local worker = net.ReadEntity();
		local system = net.ReadEntity();

		-- Do nothing if the supplied worker is not ready or empty.
		if (worker.Particles == nil) then return; end

		-- Upload configuration to system.
		local data = GLOBALS_3D_PARTICLE_EDITOR:SerializeParticles(worker);
		local particles = GLOBALS_3D_PARTICLE_EDITOR:ParseConfiguration(data);
		system:InitializeParticles(particles);
	end);
end