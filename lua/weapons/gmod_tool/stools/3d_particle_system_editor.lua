
TOOL.Category 	= "Effects";
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
	system:SetAngles(Angle(0, 0, 0));
	system:SetParent(nil);
end

function TOOL:UpdateParticleSystemParent(parent)

	-- If the parent is invalid, do nothing.
	if (!parent:IsValid()) then return; end
	self:GetWeapon():SetNWEntity("Parent", parent);

	-- Parent system to entity.
	local system = self:GetWeapon():GetNWEntity("System");
	system:SetPos(parent:GetPos());
	system:SetParent(parent, self:GetClientNumber("parent_attachment"));
end

function TOOL:LeftClick(trace)

	if (!SERVER) then return; end

	-- Weapon acts as the worker for data transfer between the system and the editor.
	-- This could be any entity but since we are using a tool, it makes sense to use
	-- the weapon reference of that tool for the duration of the editor's lifetime.
	local worker = self:GetWeapon();
	net.Start("3d_particle_system_upload_config");
		net.WriteEntity(worker)
		net.WriteEntity(worker:GetNWEntity("System"));
	net.Broadcast();

	return true;
end

function TOOL:RightClick(trace)

	if (!SERVER) then return; end

	-- Delegate positioning and parenting to appropriate method.
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

	local worker = self:GetWeapon();
	local system = worker:GetNWEntity("System");

	-- Initialize control panel once the weapon entity is valid since we will be using it client side
	-- for networking the editor data to the particle system.
	if (CLIENT && !self.PanelInitialized && worker != NULL && worker != nil && worker:IsValid()) then

		local panel = controlpanel.Get("3d_particle_system_editor");
		panel:ClearControls();

		self.BuildCPanel(panel, worker);
		self.PanelInitialized = true;
	end

	-- Particle system emitter not initialized yet, create it and keep a reference for networking.
	if (SERVER && (system == NULL || system == nil || !system:IsValid())) then

		local emitter = ents.Create("3d_particle_system");
		emitter:SetLifeTime(60 * 60)
		emitter:SetPos(Vector(0, 0, 0));
		emitter:Spawn();

		worker:SetNWEntity("System", emitter);
	end
end

function TOOL.BuildCPanel(panel, worker, config)

	-- Wait for weapon to be initialized before creating the panel.
	if (worker == nil) then return; end

	-- New particle text input.
	local entry = vgui.Create("DTextEntry");
	entry:SetValue("New Particle");
	panel:AddItem(entry);

	-- Add particle button.
	local add = panel:Button("Add Particle");
	function add:DoClick()
		GLOBALS_3D_PARTICLE_EDITOR:AddParticlePropertyPanel(worker, panel, entry);
	end

	-- Adjust parenting attachment slider.
	panel:AddControl("Slider", { Label = "#tool.3d_particle_system_editor.parent_attachment", Max = 50, Command = "3d_particle_system_editor_parent_attachment" });

	-- Add config section to editor.
	local configCategory = vgui.Create("DCollapsibleCategory");
	configCategory:SetLabel("Config");
	configCategory:SetExpanded(false);
	panel:AddItem(configCategory);

		-- Config filename input.
		local configEntry = vgui.Create("DTextEntry", configCategory);
		configEntry:SetValue("New System");
		configEntry:Dock(TOP);

		-- Save particle system button.
		local browser = nil;
		local saveConfig = vgui.Create("DButton", configCategory);
		saveConfig:SetText("Save Particle System");
		saveConfig:Dock(TOP);
		function saveConfig:DoClick()

			-- Serialize particle data and write to file. If the file exists, it will be overwritten.
			-- We also reset the file browser to the current folder, this refreshes the file list.
			local serialize = GLOBALS_3D_PARTICLE_EDITOR:SerializeParticles(worker);
			file.Write("3d_particle_system_editor/" .. configEntry:GetValue() .. ".json", serialize);
			browser:SetCurrentFolder(browser:GetCurrentFolder());
			worker:GetOwner():PrintMessage(HUD_PRINTTALK, "Saved configuration.");
		end

		-- Print particle button. The particle configuration will be printed to console.
		local printConfig = vgui.Create("DButton", configCategory);
		printConfig:SetText("Print Particle System");
		printConfig:Dock(TOP);
		function printConfig:DoClick()
			print(GLOBALS_3D_PARTICLE_EDITOR:SerializeParticles(worker));
		end

		local label = vgui.Create("DLabel", configCategory);
		label:SetText("");
		label:SetHeight(0);
		label:SetAlpha(0);
		label:Dock(TOP);

		-- Add file browser for configuration support.
		file.CreateDir("3d_particle_system_editor/");
		browser = vgui.Create("DFileBrowser", configCategory);
		browser:Dock(TOP);
		browser:SetPath("GAME");
		browser:SetBaseFolder("data");
		browser:SetOpen(true);
		browser:SetCurrentFolder("3d_particle_system_editor");
		browser:SetHeight(300);
		function browser:OnSelect(path, sender)
			label:SetText(path);
			configEntry:SetValue(string.Replace(string.match(path, "[^/]+$"), ".json", ""));
		end

		-- Load particle configuration button.
		local loadConfig = vgui.Create("DButton", configCategory);
		loadConfig:SetText("Load Config");
		loadConfig:Dock(TOP);
		function loadConfig:DoClick()

			local filePath = label:GetText();
			if (filePath != nil && filePath != "") then

				-- Call to BuildCPanel to load the configuration.
				local tool = worker:GetOwner():GetTool();
				local state = file.Read(string.Replace(filePath, "data/", ""));
				panel:ClearControls();
				tool.BuildCPanel(panel, worker, state);
				worker:GetOwner():PrintMessage(HUD_PRINTTALK, "Loaded " .. filePath);
			end
		end

	-- Load configuration file if provided.
	if (config != nil && config != "") then

		-- Deserialize and load particles onto the worker entity for data transfers.
		local particles = GLOBALS_3D_PARTICLE_EDITOR:DeserializeParticles(config, worker);

		-- Use data transfer entity to create and load properties into property panel editor.
		for k,v in pairs(particles) do
			entry:SetValue(k);
			GLOBALS_3D_PARTICLE_EDITOR:AddParticlePropertyPanel(worker, panel, entry, true);
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

	-- Debug info, to use; type developer 1 in console.
	debugoverlay.Line(pos, pos + up * 64, FrameTime() * 2, Color(0, 0, 255), true);
	debugoverlay.Line(pos, pos + right * 64, FrameTime() * 2, Color(255, 0, 0), true);
	debugoverlay.Line(pos, pos + forward * 64, FrameTime() * 2, Color(0, 255, 0), true);
	debugoverlay.Sphere(pos, 64, FrameTime() * 2, Color(255, 255, 255, 0), true);
end