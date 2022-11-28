
TOOL.Category 	= "Particles";
TOOL.Name 		= "#tool.3d_particle_system_editor.name";
TOOL.ConfigName = "";

TOOL.ClientConVar["parent_attachment"] = 0;

if (CLIENT) then

	TOOL.Information = {
		{name = "info", stage = 1},
		{name = "left"},
		{name = "right"},
		{name = "reload"}
	};

	language.Add("tool.3d_particle_system_editor.name", "3D Particle System Editor");
	language.Add("tool.3d_particle_system_editor.desc", "GUI editor to easily create and test 3D particle effects.");

	language.Add("tool.3d_particle_system_editor.left", "Play / Update particle system.");
	language.Add("tool.3d_particle_system_editor.right", "Set position / Parent to entity.");
	language.Add("tool.3d_particle_system_editor.reload", "Parent particle system to yourself.");

	language.Add("tool.3d_particle_system_editor.parent_attachment", "Parent Attachment");
end

function TOOL:UpdateParticleSystemPosition(trace)

	-- Update system's position.
	local system = self:GetWeapon():GetNWEntity("System");
	system:SetPos(trace.HitPos);
	system:SetParent(nil);
end

function TOOL:UpdateParticleSystemParent(parent)

	-- If the parent is invalid, do nothing.
	if (!parent:IsValid()) then return; end
	self:GetWeapon():SetNWEntity("Parent", parent);

	-- Parent system the entity.
	local system = self:GetWeapon():GetNWEntity("System");
	system:SetPos(parent:GetPos());
	system:SetParent(parent, self:GetClientNumber("parent_attachment"));
end

function TOOL:LeftClick(trace)

	if (!SERVER) then return; end

	-- Network weapon data to client side to start initializing particles with editor data.
	local weapon = self:GetWeapon();
	net.Start("3d_particle_system_upload_config");
		net.WriteEntity(weapon)
		net.WriteEntity(weapon:GetNWEntity("System"));
	net.Broadcast();

	return true;
end

function TOOL:RightClick(trace)

	if (!SERVER) then return; end

	-- Delegate positioning anf parenting to appropriate method.
	if (!trace.HitWorld && trace.Entity != NULL) then self:UpdateParticleSystemParent(trace.Entity);
	else self:UpdateParticleSystemPosition(trace); end

	-- Begin network call to particle system.
	self:LeftClick(trace);
	return true;
end

function TOOL:Reload()

	if (!SERVER) then return; end

	-- Begin network call to particle system.
	self:UpdateParticleSystemParent(self:GetOwner());
	self:LeftClick(trace);
	return true;
end

function TOOL:Think()

	local weapon = self:GetWeapon();
	local system = weapon:GetNWEntity("System");

	-- Initialize control panel once the weapon entity is valid since we will be using it client side
	-- for networking the editor data to the particle system.
	if (CLIENT && !self.PanelInitialized && weapon != NULL && weapon != nil && weapon:IsValid()) then

		local panel = controlpanel.Get("3d_particle_system_editor");
		panel:ClearControls();

		self.BuildCPanel(panel, weapon, "{\"Particle 1\":{\"StartColor\":{\"r\":255,\"g\":255,\"b\":255,\"a\":255},\"RotationNormal\":\"[0 0 0]\",\"ColorFunctionMod\":1,\"Delay\":0,\"AlphaFunctionMod\":1,\"UseEndColor\":false,\"EndAlpha\":0,\"ColorFunction\":\"Sine\",\"StartRotation\":0,\"RotationFunction\":\"Sine\",\"LifeTime\":1,\"UseEndAlpha\":false,\"BodyGroups\":\"0\",\"AlphaFunction\":\"Sine\",\"RotateAroundNormal\":true,\"LocalPos\":\"[0 0 0]\",\"RotationFunctionMod\":1,\"Looping\":false,\"InheritPos\":true,\"StartAlpha\":255,\"ScaleAxis\":\"[1 1 1]\",\"UseScaleAxis\":false,\"ScaleFunctionMod\":1,\"InheritLifeTime\":false,\"Skin\":0,\"EndColor\":{\"r\":255,\"g\":255,\"b\":255,\"a\":255},\"Material\":\"models/props_combine/portalball001_sheet\",\"UseEndRotation\":false,\"Angles\":\"{0 0 0}\",\"Pos\":\"[0 0 0]\",\"EndRotation\":0,\"ScaleFunction\":\"Sine\",\"UseEndScale\":true,\"EndScale\":10,\"Model\":\"models/hunter/misc/sphere075x075.mdl\",\"StartScale\":1}}");
		self.PanelInitialized = true;
	end

	-- Particle system emitter not initialized yet, create it and keep a reference for networking.
	if (SERVER && (system == NULL || system == nil || !system:IsValid())) then

		local emitter = ents.Create("3d_particle_system");
		emitter:SetLifeTime(60 * 60)
		emitter:SetPos(Vector(0, 0, 0));
		emitter:Spawn();

		weapon:SetNWEntity("System", emitter);
	end
end

local function SetParticlePropertyValue(weapon, particle, prop, type, value)

	-- Vector color is a special case. We handle JSON serialization manually since its data
	-- structure is unique and differs from vectors and angles.
	if (type == "VectorColor") then
		weapon.Particles[particle:GetText()][prop] = GLOBALS_3D_PARTICLE_EDITOR:ToColor(value);
		return;
	end

	if (type == "Generic" || type == "Combo") then
		weapon.Particles[particle:GetText()][prop] = GLOBALS_3D_PARTICLE_EDITOR:ToGeneric(value);
		return;
	end

	weapon.Particles[particle:GetText()][prop] = value;
end

local function GetPropertyDefault(weapon, particle, prop, type, fallback)

	local property = weapon.Particles[particle:GetText()][prop];
	if (property != nil) then

		if (type == "VectorColor") then
			local color = util.JSONToTable(property);
			return Vector(color.r, color.g, color.b);
		end

		if (type == "Generic" || type == "Combo") then
			return string.sub(property, 2, -2);
		end
	end

	return property || fallback;
end

local function AddParticlePropertyPanel(weapon, panel, particle, prop, category, name, type, settings, choices, default, useConfig)

	-- Create property editor.
	local defaultValue = GetPropertyDefault(weapon, particle, prop, type, default);

	if (!useConfig) then
		SetParticlePropertyValue(weapon, particle, prop, type, defaultValue);
	end

	local editor = panel:CreateRow(category, name);
	editor:Setup(type, settings);
	editor.DataChanged = function(_, val)

		if (type == "Boolean") then
			if (val == 1) then SetParticlePropertyValue(weapon, particle, prop, type, true);
			else SetParticlePropertyValue(weapon, particle, prop, type, false); end
			return;
		end

		if (type == "VectorColor") then
			local color = string.Split(val, " ");
			SetParticlePropertyValue(weapon, particle, prop, type, Vector(color[1] * 255, color[2] * 255, color[3] * 255));
			return;
		end

		SetParticlePropertyValue(weapon, particle, prop, type, val);
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

local function AddParticlePanel(weapon, panel, entry, useConfig)

	-- Do nothing if the particle we are trying to create already exists.
	local particleName = entry:GetValue();
	if (weapon.Particles[particleName] != nil && !useConfig) then
		return;
	end

	-- Initialize particle array for editor key values.
	if (!useConfig) then
		weapon.Particles[particleName] = {};
	end

	-- Particle collapsible category.
	local category = vgui.Create("DCollapsibleCategory");
	category:SetLabel(entry:GetValue());
	category:SetExpanded(false);
	panel:AddItem(category);

		-- Generic label. This will be hidden an contain the key of the particle.
		-- The instance will be used as a pass by reference pointer when renaming
		-- particles in the system using the editor.
		local label = vgui.Create("DLabel", category);
		label:SetText(particleName);
		label:SetHeight(0);
		label:SetAlpha(0);
		label:Dock(TOP);

		-- Rename button.
		local renameButton = vgui.Create("DButton", category);
		renameButton:SetText("Rename");
		renameButton:Dock(TOP);
		function renameButton:DoClick()

			local newKey = entry:GetValue();
			if (weapon.Particles[newKey] != nil) then
				return;
			end

			-- Copy data over and delete old key references.
			local oldKey = label:GetText();
			weapon.Particles[newKey] = weapon.Particles[oldKey];
			weapon.Particles[oldKey] = nil;
			category:SetLabel(newKey);
			label:SetText(newKey);
		end

		-- Remove button.
		local deleteButton = vgui.Create("DButton", category);
		deleteButton:SetText("Delete");
		deleteButton:Dock(TOP);
		function deleteButton:DoClick()

			-- Delete entries to the particles properties array.
			local oldKey = label:GetText();
			weapon.Particles[oldKey] = nil;
			category:Remove();
		end

		-- Generic panel for layout.
		local container = vgui.Create("DPanel", category);
		container:Dock(TOP);
		category:SetContents(container);

			-- Particle properties list.
			local particleProps = vgui.Create("DProperties", container);
			particleProps:SetHeight(905);
			particleProps:Dock(TOP);

				-- Rendering properties.
				local model = "models/hunter/misc/sphere075x075.mdl";
				local material = "models/props_combine/portalball001_sheet";
				AddParticlePropertyPanel(weapon, particleProps, label, "Model", 				"Rendering", "Model", 				"Generic", 		{}, nil, model, useConfig);
				AddParticlePropertyPanel(weapon, particleProps, label, "Skin", 					"Rendering", "Skin", 				"Int", 			{ min = 0, max = 100 }, nil, 0, useConfig);
				AddParticlePropertyPanel(weapon, particleProps, label, "BodyGroups", 			"Rendering", "Body Groups", 		"Generic", 		{}, nil, "0", useConfig);
				AddParticlePropertyPanel(weapon, particleProps, label, "Material", 				"Rendering", "Material", 			"Generic", 		{}, nil, material, useConfig);

				-- Transform properties.
				AddParticlePropertyPanel(weapon, particleProps, label, "InheritPos", 			"Transform", "Inherit Pos", 		"Boolean", 		{}, nil, true, useConfig);
				AddParticlePropertyPanel(weapon, particleProps, label, "Pos", 					"Transform", "Position", 			"Generic", 		{}, nil, "[0 0 0]", useConfig);
				AddParticlePropertyPanel(weapon, particleProps, label, "LocalPos", 				"Transform", "Local Position", 		"Generic", 		{}, nil, "[0 0 0]", useConfig);
				AddParticlePropertyPanel(weapon, particleProps, label, "Angles", 				"Transform", "Angles", 				"Generic", 		{}, nil, "{0 0 0}", useConfig);

				-- Timing properties.
				AddParticlePropertyPanel(weapon, particleProps, label, "Delay", 				"Timing", "Delay", 					"Float", 		{ min = 0, max = 60 }, nil, 0, useConfig);
				AddParticlePropertyPanel(weapon, particleProps, label, "InheritLifeTime", 		"Timing", "Inherit Life Time", 		"Boolean", 		{}, nil, false, useConfig);
				AddParticlePropertyPanel(weapon, particleProps, label, "LifeTime", 				"Timing", "Life Time", 				"Float", 		{ min = 0, max = 60 * 5 }, nil, 1, useConfig);
				AddParticlePropertyPanel(weapon, particleProps, label, "Looping", 				"Timing", "Looping", 				"Boolean", 		{}, nil, false, useConfig);

				-- Rotation properties.
				AddParticlePropertyPanel(weapon, particleProps, label, "RotationFunction", 		"Rotation", "Function", 			"Combo", 		{}, GLOBALS_3D_PARTICLE_EDITOR.MathFunctionsConversionTable, "Sine", useConfig);
				AddParticlePropertyPanel(weapon, particleProps, label, "RotationNormal", 		"Rotation", "Rotation Normal", 		"Generic", 		{}, nil, "[0 0 0]", useConfig);
				AddParticlePropertyPanel(weapon, particleProps, label, "RotateAroundNormal", 	"Rotation", "Rotate Around Normal", "Boolean", 		{}, nil, true, useConfig);
				AddParticlePropertyPanel(weapon, particleProps, label, "StartRotation", 		"Rotation", "Start Rotation", 		"Float", 		{ min = -360000, max = 360000 }, nil, 0, useConfig);
				AddParticlePropertyPanel(weapon, particleProps, label, "UseEndRotation", 		"Rotation", "Use End Rotation", 	"Boolean", 		{}, nil, false, useConfig);
				AddParticlePropertyPanel(weapon, particleProps, label, "EndRotation", 			"Rotation", "End Rotation", 		"Float", 		{ min = -360000, max = 360000 }, nil, 0, useConfig);
				AddParticlePropertyPanel(weapon, particleProps, label, "RotationFunctionMod", 	"Rotation", "Rotation Rate", 		"Float", 		{ min = -360000, max = 360000 }, nil, 1, useConfig);

				-- Color properties.
				AddParticlePropertyPanel(weapon, particleProps, label, "ColorFunction", 		"Color", "Function", 				"Combo", 		{}, GLOBALS_3D_PARTICLE_EDITOR.MathFunctionsConversionTable, "Sine", useConfig);
				AddParticlePropertyPanel(weapon, particleProps, label, "StartColor", 			"Color", "Start Color", 			"VectorColor", 	{}, nil, Vector(255, 255, 255), useConfig);
				AddParticlePropertyPanel(weapon, particleProps, label, "UseEndColor", 			"Color", "Use End Color", 			"Boolean", 		{}, nil, false, useConfig);
				AddParticlePropertyPanel(weapon, particleProps, label, "EndColor", 				"Color", "End Color", 				"VectorColor", 	{}, nil, Vector(255, 255, 255), useConfig);
				AddParticlePropertyPanel(weapon, particleProps, label, "ColorFunctionMod", 		"Color", "Color Rate", 				"Float", 		{ min = -360000, max = 360000 }, nil, 1, useConfig);

				-- Alpha properties.
				AddParticlePropertyPanel(weapon, particleProps, label, "AlphaFunction", 		"Alpha", "Function", 				"Combo", 		{}, GLOBALS_3D_PARTICLE_EDITOR.MathFunctionsConversionTable, "Sine", useConfig);
				AddParticlePropertyPanel(weapon, particleProps, label, "StartAlpha", 			"Alpha", "Start Alpha", 			"Float", 		{ min = 0, max = 255 }, nil, 255, useConfig);
				AddParticlePropertyPanel(weapon, particleProps, label, "UseEndAlpha", 			"Alpha", "Use End Alpha", 			"Boolean", 		{}, nil, false, useConfig);
				AddParticlePropertyPanel(weapon, particleProps, label, "EndAlpha", 				"Alpha", "End Alpha", 				"Float", 		{ min = 0, max = 255 }, nil, 0, useConfig);
				AddParticlePropertyPanel(weapon, particleProps, label, "AlphaFunctionMod", 		"Alpha", "Alpha Rate", 				"Float", 		{ min = -360000, max = 360000 }, nil, 1, useConfig);

				-- Scale properties.
				AddParticlePropertyPanel(weapon, particleProps, label, "ScaleFunction", 		"Scale", "Function", 				"Combo", 		{}, GLOBALS_3D_PARTICLE_EDITOR.MathFunctionsConversionTable, "Sine", useConfig);
				AddParticlePropertyPanel(weapon, particleProps, label, "StartScale", 			"Scale", "Start Scale", 			"Float", 		{ min = 0, max = 360000 }, nil, 1, useConfig);
				AddParticlePropertyPanel(weapon, particleProps, label, "UseEndScale", 			"Scale", "Use End Scale", 			"Boolean", 		{}, nil, false, useConfig);
				AddParticlePropertyPanel(weapon, particleProps, label, "EndScale", 				"Scale", "End Scale", 				"Float", 		{ min = 0, max = 360000 }, nil, 0, useConfig);
				AddParticlePropertyPanel(weapon, particleProps, label, "ScaleFunctionMod", 		"Scale", "Scale Rate", 				"Float", 		{ min = -360000, max = 360000 }, nil, 1, useConfig);
				AddParticlePropertyPanel(weapon, particleProps, label, "UseScaleAxis", 			"Scale", "Use Scale Axis", 			"Boolean", 		{}, nil, false, useConfig);
				AddParticlePropertyPanel(weapon, particleProps, label, "ScaleAxis", 			"Scale", "Scale Axis", 				"Generic", 		{}, nil, "[1 1 1]", useConfig);
end

function TOOL.BuildCPanel(panel, weapon, config)

	-- Wait for weapon to be initialized before creating the panel.
	if (weapon == nil) then return; end

	-- Prepare weapon to hold client side references.
	if (weapon.Particles == nil) then
		weapon.Particles = {};
	end

	-- New particle text input.
	local entry = vgui.Create("DTextEntry");
	entry:SetValue("Particle 1");
	panel:AddItem(entry);

	-- Add particle button.
	local add = panel:Button("Add Particle");
	function add:DoClick()
		AddParticlePanel(weapon, panel, entry);
	end

	-- Adjust parenting attachment.
	panel:AddControl("Slider", { Label = "#tool.3d_particle_system_editor.parent_attachment", Max = 50, Command = "3d_particle_system_editor_parent_attachment" });

	-- Add config section to editor.
	local configCategory = vgui.Create("DCollapsibleCategory");
	configCategory:SetLabel("Config");
	configCategory:SetExpanded(false);
	panel:AddItem(configCategory);

		-- Print particle button.
		local printConfig = vgui.Create("DButton", configCategory);
		printConfig:SetText("Print Config");
		printConfig:Dock(TOP);
		function printConfig:DoClick()
			print(GLOBALS_3D_PARTICLE_EDITOR:SerializeParticles(weapon));
		end

	-- Load configuration file if provided.
	if (config != nil && config != "") then
		weapon.Particles = GLOBALS_3D_PARTICLE_EDITOR:DeserializeParticles(config);
		for k,v in pairs(weapon.Particles) do
			entry:SetValue(k);
			AddParticlePanel(weapon, panel, entry, true);
		end
	end
end

function TOOL:DrawHUD()

	local system = self:GetWeapon():GetNWEntity("System");
	if (system == NULL || system == nil || !system:IsValid()) then
		return;
	end

	local pos = system:GetPos();
	local angles = system:GetAngles();
	local up = angles:Up();
	local right = angles:Right();
	local forward = angles:Forward();

	-- Debug data if developer is turned on.
	debugoverlay.Line(pos, pos + up * 64, FrameTime() * 2, Color(0, 0, 255), true);
	debugoverlay.Line(pos, pos + right * 64, FrameTime() * 2, Color(255, 0, 0), true);
	debugoverlay.Line(pos, pos + forward * 64, FrameTime() * 2, Color(0, 255, 0), true);
	debugoverlay.Sphere(pos, 64, FrameTime() * 2, Color(255, 255, 255, 0), true);
end