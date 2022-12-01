
-- This behaves like a static class.
GLOBALS_3D_PARTICLE_EDITOR = {};

-- Used to parse colors.
function GLOBALS_3D_PARTICLE_EDITOR:ToColor(data)
	return "{\"r\":" .. math.floor(data.r) .. ",\"g\":" .. math.floor(data.g) .. ",\"b\":" .. math.floor(data.b) .. "}";
end

--!
--! @brief      Serializes the particles on the worker. All the values form the editor are already
--! 			In JSON format, this function simply constructs the JSON table for the system and particles.
--!
--! @param      worker  The worker entity containing the particles.
--!
--! @return     Particle system in JSON format.
--!
function GLOBALS_3D_PARTICLE_EDITOR:SerializeParticles(worker)

	local data = "{";
	for k,v in pairs(worker.Particles) do

		if (!v["Enable"]) then continue; end

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

--!
--! @brief      Loads a value onto the desired property of a particle. This function also converts
--! 			the value into the the appropriate JSON data structure.
--!
--! @param      worker    The worker containing the particle's property to update.
--! @param      particle  The particle being modified.
--! @param      prop      The property to update.
--! @param      type      The data type of that property.
--! @param      value     The desired value.
--!
function GLOBALS_3D_PARTICLE_EDITOR:SetParticlePropertyValue(worker, particle, prop, type, value)

	-- Vector color is a special case. We handle JSON serialization manually since its data
	-- structure is unique and differs from vectors and angles.
	if (type == "Color") then
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

--!
--! @brief      Will return the desired property from the particle if it exists. If it does not
--! 			exist, will return the fallback value instead. This is mainly used for setting
--! 			up the editor when loading a configuration, or when instancing a new editor.
--!				This function will also convert from JSON to the editor's data type.
--!
--! @param      worker    The worker containing the particles.
--! @param      particle  The particle from which to retreive the property.
--! @param      prop      The property to return.
--! @param      type      The type of that property.
--! @param      fallback  The fallback to use if the property is not set.
--!
--! @return     Property default.
--!
function GLOBALS_3D_PARTICLE_EDITOR:GetPropertyDefault(worker, particle, prop, type, fallback)

	-- Determine if the worker already contains a configuration file.
	local property = worker.Particles[particle:GetText()][prop];
	if (property != nil) then

		-- Convert JSON color datatype to a lua Vector datatype.
		if (type == "Color") then
			local color = util.JSONToTable(property);
			return Color(color.r, color.g, color.b);
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

--!
--! @brief      Adds a particle property editable panel to the editor for a particle. For more
--! 			information on the Derma being created, see: https://wiki.facepunch.com/gmod/DProperties:CreateRow
--!
--! @param      worker     The worker containing the particles.
--! @param      panel      The panel onto which the row will be added, this should be a DProperties component.
--! @param      particle   The particle for which to add the editor.
--! @param      prop       The property of the particle for which to add the editor.
--! @param      category   Grouping parameter for the DProperties.
--! @param      name       The name of the property in text form.
--! @param      type       The type of that property.
--! @param      settings   The settings, if any. This is used to set a 'min' and a 'max' for example.
--! @param      choices    The choices, only for ComboBoxes.
--! @param      default    The default value to set on the editor.
--! @param      useConfig  If set to true, will not update the worker. This is used when first loading a config.
--!
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

		-- Convert Source color datatype to a lua Color datatype.
		if (type == "Color") then
			local color = string.Split(val, " ");
			self:SetParticlePropertyValue(worker, particle, prop, type, Color(tonumber(color[1]) || 0, tonumber(color[2]) || 0, tonumber(color[3]) || 0));
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

--!
--! @brief      The meat of the editor. This will create the editor panel with all the properties
--! 			for an individual particle. This panel is also generic and could theoretically be
--! 			reused in an Derma component if you desire. To do so, you must have a good grasp
--! 			on what the worker is.
--!
--! @param      worker      The worker entity that will contain the particle for data transfer.
--! @param      panel       The panel onto which the editor panel will be added.
--! @param      dtextentry  The dtextentry to use for the name of the particle. This must be the
--! 						component itself in order to use pass by reference when renaming.
--! @param      useConfig   If set to true, will prevent updating the the worker with default values.
--!
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
			particleProps:SetHeight(1010);
			particleProps:Dock(TOP);

				-- Rendering properties.
				local model = "models/hunter/misc/sphere075x075.mdl";
				local material = "Models/effects/comball_sphere";
				self:AddParticlePropertyRow(worker, particleProps, label, "Enable", 			"Rendering", "Enable", 				"Boolean", 		{}, nil, true, useConfig);
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
				self:AddParticlePropertyRow(worker, particleProps, label, "RotationFunction", 	"Rotation", "Function", 			"Combo", 		{}, GLOBALS_3D_PARTICLE_PARSER.MathFunctionsConversionTable, "Sine", useConfig);
				self:AddParticlePropertyRow(worker, particleProps, label, "RotationNormal", 	"Rotation", "Rotation Normal", 		"Generic", 		{}, nil, "[0 0 1]", useConfig);
				self:AddParticlePropertyRow(worker, particleProps, label, "ConstantRotation", 	"Rotation", "Constant Rotation", 	"Boolean", 		{}, nil, true, useConfig);
				self:AddParticlePropertyRow(worker, particleProps, label, "StartRotation", 		"Rotation", "Start Rotation", 		"Float", 		{ min = -360000, max = 360000 }, nil, 0, useConfig);
				self:AddParticlePropertyRow(worker, particleProps, label, "UseEndRotation", 	"Rotation", "Use End Rotation", 	"Boolean", 		{}, nil, false, useConfig);
				self:AddParticlePropertyRow(worker, particleProps, label, "EndRotation", 		"Rotation", "End Rotation", 		"Float", 		{ min = -360000, max = 360000 }, nil, 0, useConfig);
				self:AddParticlePropertyRow(worker, particleProps, label, "RotationFunctionMod","Rotation", "Rotation Rate", 		"Float", 		{ min = -360000, max = 360000 }, nil, 1, useConfig);

				-- Color properties.
				self:AddParticlePropertyRow(worker, particleProps, label, "ColorFunction", 		"Color", "Function", 				"Combo", 		{}, GLOBALS_3D_PARTICLE_PARSER.MathFunctionsConversionTable, "Sine", useConfig);
				self:AddParticlePropertyRow(worker, particleProps, label, "StartColor", 		"Color", "Start Color", 			"Color", 		{}, nil, Color(255, 255, 255), useConfig);
				self:AddParticlePropertyRow(worker, particleProps, label, "UseEndColor", 		"Color", "Use End Color", 			"Boolean", 		{}, nil, false, useConfig);
				self:AddParticlePropertyRow(worker, particleProps, label, "EndColor", 			"Color", "End Color", 				"Color", 		{}, nil, Color(255, 255, 255), useConfig);
				self:AddParticlePropertyRow(worker, particleProps, label, "ColorFunctionMod", 	"Color", "Color Rate", 				"Float", 		{ min = -360000, max = 360000 }, nil, 1, useConfig);

				-- Alpha properties.
				self:AddParticlePropertyRow(worker, particleProps, label, "AlphaFunction", 		"Alpha", "Function", 				"Combo", 		{}, GLOBALS_3D_PARTICLE_PARSER.MathFunctionsConversionTable, "Sine", useConfig);
				self:AddParticlePropertyRow(worker, particleProps, label, "StartAlpha", 		"Alpha", "Start Alpha", 			"Float", 		{ min = 0, max = 255 }, nil, 255, useConfig);
				self:AddParticlePropertyRow(worker, particleProps, label, "UseEndAlpha", 		"Alpha", "Use End Alpha", 			"Boolean", 		{}, nil, false, useConfig);
				self:AddParticlePropertyRow(worker, particleProps, label, "EndAlpha", 			"Alpha", "End Alpha", 				"Float", 		{ min = 0, max = 255 }, nil, 0, useConfig);
				self:AddParticlePropertyRow(worker, particleProps, label, "AlphaFunctionMod", 	"Alpha", "Alpha Rate", 				"Float", 		{ min = -360000, max = 360000 }, nil, 1, useConfig);

				-- Scale properties.
				self:AddParticlePropertyRow(worker, particleProps, label, "ScaleFunction", 		"Scale", "Function", 				"Combo", 		{}, GLOBALS_3D_PARTICLE_PARSER.MathFunctionsConversionTable, "Sine", useConfig);
				self:AddParticlePropertyRow(worker, particleProps, label, "StartScale", 		"Scale", "Start Scale", 			"Float", 		{ min = 0, max = 360000 }, nil, 1, useConfig);
				self:AddParticlePropertyRow(worker, particleProps, label, "UseEndScale", 		"Scale", "Use End Scale", 			"Boolean", 		{}, nil, false, useConfig);
				self:AddParticlePropertyRow(worker, particleProps, label, "EndScale", 			"Scale", "End Scale", 				"Float", 		{ min = 0, max = 360000 }, nil, 0, useConfig);
				self:AddParticlePropertyRow(worker, particleProps, label, "ScaleFunctionMod", 	"Scale", "Scale Rate", 				"Float", 		{ min = -360000, max = 360000 }, nil, 1, useConfig);

				-- Axis scale properties.
				self:AddParticlePropertyRow(worker, particleProps, label, "AxisScaleFunction", 	"Axis", "Function", 				"Combo", 		{}, GLOBALS_3D_PARTICLE_PARSER.MathFunctionsConversionTable, "Sine", useConfig);
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

--!
--! @brief      Save the worker's particle configuration to a JSON file.
--!
--! @param      worker  The worker containing the particle data.
--! @param      name    The name of the JSON file.
--! @param      path    The path to use to save the file. Relative to 'DATA' folder.
--! @param      silent  If set to true, will not print to the player's HUD. Used for auto-save.
--!
--! @return     True on success, False on failure.
--!
function GLOBALS_3D_PARTICLE_EDITOR:Save(worker, name, path, silent)

	local function tablelength(T)
		local count = 0;
		for _ in pairs(T) do count = count + 1; end
		return count;
	end

	if (worker.Particles == nil || tablelength(worker.Particles) <= 0) then
		if (!silent) then worker:GetOwner():PrintMessage(HUD_PRINTTALK, "Nothing to save."); end
		return;
	end

	-- Serialize particle data and write to file. If the file exists, it will be overwritten.
	local serialize = GLOBALS_3D_PARTICLE_EDITOR:SerializeParticles(worker);
	local configFile = string.Replace(path .. "/" .. name .. ".json", "data/", "");
	file.Write(configFile, serialize);
	if (!file.Exists(configFile, "DATA")) then
		if (!silent) then worker:GetOwner():PrintMessage(HUD_PRINTTALK, "Error: Configuration could not be saved. To backup, use 'Print Particle System' and copy the result from the console."); end
		return false;
	else
		if (!silent) then worker:GetOwner():PrintMessage(HUD_PRINTTALK, "Saved configuration."); end
		return true;
	end
end

--!
--! Data transfer code. This is the part responsible for converting the data from the editor
--! into an actual particle in the world. The worker entity should contain an array named
--! 'Particles' that will get parsed into a Source Engine data structure. The final configuration
--! will then be loaded into the InitializeParticles function of a 3d_particle_system_base entity.
--! This code is made specifically for the editor and should not be reused in any projects unless
--! creating a new editor.
--!
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