
-- This behaves like a static class.
GLOBALS_3D_PARTICLE_EDITOR = {};

-- Used to parse colors.
function GLOBALS_3D_PARTICLE_EDITOR:ToColor(data)
	return "{\"r\":" .. data[1] .. ",\"g\":" .. data[2] .. ",\"b\":" .. data[3] .. ",\"a\":255}";
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

function GLOBALS_3D_PARTICLE_EDITOR:SetParticlePropertyValue(worker, particle, prop, type, value)

	-- Vector color is a special case. We handle JSON serialization manually since its data
	-- structure is unique and differs from vectors and angles.
	if (type == "VectorColor") then
		worker.Particles[particle:GetText()][prop] = GLOBALS_3D_PARTICLE_EDITOR:ToColor(value);
		return;
	end

	-- Add surrounding quotes to lua string datatype ("example") in order to be a JSON datatype (""example"").
	if (type == "Generic" || type == "Combo") then
		worker.Particles[particle:GetText()][prop] = GLOBALS_3D_PARTICLE_PARSER:ToGeneric(value);
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

		return property;
	end

	-- If the property is nil, or we are not using a configuration file,
	-- this will default to using the supplied fallback value.
	return fallback;
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

		-- Generic panel for layout.
		local container = vgui.Create("DPanel", category);
		container:Dock(TOP);
		category:SetContents(container);

			-- Particle properties list.
			local particleProps = vgui.Create("DProperties", container);
			particleProps:SetHeight(990);
			particleProps:Dock(TOP);

				-- Rendering properties.
				local model = "models/hunter/misc/sphere075x075.mdl";
				local material = "Models/effects/comball_sphere";
				self:AddParticlePropertyRow(worker, particleProps, label, "Model", 				"Rendering", "Model", 				"Generic", 		{}, nil, model, useConfig);
				self:AddParticlePropertyRow(worker, particleProps, label, "Skin", 				"Rendering", "Skin", 				"Int", 			{ min = 0, max = 100 }, nil, 0, useConfig);
				self:AddParticlePropertyRow(worker, particleProps, label, "BodyGroups", 		"Rendering", "Body Groups", 		"Generic", 		{}, nil, "0", useConfig);
				self:AddParticlePropertyRow(worker, particleProps, label, "Material", 			"Rendering", "Material", 			"Generic", 		{}, nil, material, useConfig);

				-- Transform properties.
				self:AddParticlePropertyRow(worker, particleProps, label, "InheritPos", 		"Transform", "Inherit Pos", 		"Boolean", 		{}, nil, true, useConfig);
				self:AddParticlePropertyRow(worker, particleProps, label, "Pos", 				"Transform", "Position", 			"Generic", 		{}, nil, "[0 0 0]", useConfig);
				self:AddParticlePropertyRow(worker, particleProps, label, "Angles", 			"Transform", "Angles", 				"Generic", 		{}, nil, "{0 0 0}", useConfig);
				self:AddParticlePropertyRow(worker, particleProps, label, "InheritAngles", 		"Transform", "Inherit System Angles","Boolean",		{}, nil, false, useConfig);

				-- Timing properties.
				self:AddParticlePropertyRow(worker, particleProps, label, "Delay", 				"Timing", "Delay", 					"Float", 		{ min = 0, max = 60 }, nil, 0, useConfig);
				self:AddParticlePropertyRow(worker, particleProps, label, "InheritLifeTime", 	"Timing", "Inherit Life Time", 		"Boolean", 		{}, nil, false, useConfig);
				self:AddParticlePropertyRow(worker, particleProps, label, "LifeTime", 			"Timing", "Life Time", 				"Float", 		{ min = 0, max = 60 * 5 }, nil, 1, useConfig);
				self:AddParticlePropertyRow(worker, particleProps, label, "Looping", 			"Timing", "Looping", 				"Boolean", 		{}, nil, false, useConfig);

				-- Rotation properties.
				self:AddParticlePropertyRow(worker, particleProps, label, "RotationFunction", 	"Rotation", "Function", 			"Combo", 		{}, self.MathFunctionsConversionTable, "Sine", useConfig);
				self:AddParticlePropertyRow(worker, particleProps, label, "RotationNormal", 	"Rotation", "Rotation Normal", 		"Generic", 		{}, nil, "[0 0 1]", useConfig);
				self:AddParticlePropertyRow(worker, particleProps, label, "ConstantRotation", 	"Rotation", "Constant Rotation", 	"Boolean", 		{}, nil, true, useConfig);
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
				self:AddParticlePropertyRow(worker, particleProps, label, "EndAxisScale", 		"Axis", "End Axis Scaling", 		"Generic", 		{}, nil, "[1 1 1]", useConfig);
				self:AddParticlePropertyRow(worker, particleProps, label, "AxisScaleFunctionMod","Axis","Axis Scale Rate", 			"Float", 		{ min = -360000, max = 360000 }, nil, 1, useConfig);

		-- Remove button.
		local delete = vgui.Create("DButton", container);
		delete:SetText("Delete");
		delete:Dock(TOP);
		function delete:DoClick()

			-- Delete entries to the particles properties array.
			local oldKey = label:GetText();
			worker.Particles[oldKey] = nil;
			category:Remove();
		end
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
		local particles = GLOBALS_3D_PARTICLE_PARSER:ParseConfiguration(data);
		system:InitializeParticles(particles);
	end);
end