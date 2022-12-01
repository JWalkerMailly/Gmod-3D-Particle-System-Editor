
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

--!
--! @brief      Sets the particle system's position in the world. Will also align
--! 			the system's angles to match the surface it is on.
--!
--! @param      trace  The tool trace.
--!	
function TOOL:UpdateParticleSystemPosition(trace)

	-- Align to surface.
	local impactCross = trace.HitNormal:Angle():Forward():Cross(Vector(0, 0, -1));
	local impactAngle = impactCross:AngleEx(trace.HitNormal);

	-- Update system's position.
	local system = self:GetWeapon():GetNWEntity("System");
	system:SetPos(trace.HitPos);
	system:SetAngles(impactAngle);
	system:SetParent(nil);
end

--!
--! @brief      Update the parent of the particle system. Will make use of the attachment 
--! 			slider found in the tool menu to determine the attach point.
--!				
--! @param      parent  The parent.
--!
function TOOL:UpdateParticleSystemParent(parent)

	-- If the parent is invalid, do nothing.
	if (!parent:IsValid()) then return; end
	self:GetWeapon():SetNWEntity("Parent", parent);

	-- Parent system to entity.
	local system = self:GetWeapon():GetNWEntity("System");
	system:SetPos(parent:GetPos());
	system:SetParent(parent, self:GetClientNumber("parent_attachment"));
end

--!
--! @brief      Left click controls.
--!
--! @param      trace  The tool trace.
--!
--! @return     False to avoid playing the tool beam effect and animation.
--!
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

	return false;
end

--!
--! @brief      Right click controls.
--!
--! @param      trace  The tool trace.
--!
--! @return     True to play the beam effect and animations.
--!
function TOOL:RightClick(trace)

	if (!SERVER) then return; end

	-- Delegate positioning and parenting to appropriate method.
	if (!trace.HitWorld && trace.Entity != NULL) then self:UpdateParticleSystemParent(trace.Entity);
	else self:UpdateParticleSystemPosition(trace); end

	-- Begin network call to particle system.
	self:LeftClick(trace);
	return true;
end

--!
--! @brief      Reload controls. This will parent the particle system to the owner.
--!
--! @return     False to avoid playing the beam effect and animations.
--!
function TOOL:Reload()

	if (!SERVER) then return; end

	-- Begin network call to particle system.
	self:UpdateParticleSystemParent(self:GetOwner());
	self:LeftClick(trace);
	return false;
end

--!
--! @brief      Editor and data transfer lifetime. If the datatransfer worker (weapon) is valid
--!				we create the tool panel to start creating particle systems. If the particle
--!				system ever dies (default lifetime of 1 hour), we recreate it. 
--!
--! @return     { description_of_the_return_value }
--!
function TOOL:Think()

	local worker = self:GetWeapon();
	local system = worker:GetNWEntity("System");
	local workerValid = worker != NULL && worker != nil && worker:IsValid();
	local systemValid = system != NULL && system != nil && system:IsValid();

	-- Initialize control panel once the weapon entity is valid since we will be using it client side
	-- for networking the editor data to the particle system.
	if (CLIENT && !self.PanelInitialized && workerValid) then

		local panel = controlpanel.Get("3d_particle_system_editor");
		panel:ClearControls();

		self.BuildCPanel(panel, worker);
		self.PanelInitialized = true;
	end

	-- Particle system emitter not initialized yet, create it and keep a reference for networking.
	if (SERVER && !systemValid) then

		local emitter = ents.Create("3d_particle_system_base");
		emitter:SetLifeTime(60 * 60)
		emitter:SetPos(Vector(0, 0, 0));
		emitter:Spawn();

		worker:SetNWEntity("System", emitter);
	end

	-- Auto save feature.
	if (workerValid && systemValid && CurTime() > (self.LastAutoSave || 0)) then
		GLOBALS_3D_PARTICLE_EDITOR:Save(worker, "autosave", "data/3d_particle_system_editor", true);
		self.LastAutoSave = CurTime() + 30;
	end
end

--!
--! @brief      Builds a control panel.
--!
--! @param      panel       The panel that was built.
--! @param      worker      The datatransfer worker. This will be the tool's weapon entity.
--! @param      config      The configuration file, if provided.
--! @param      name        The name of the system being edited, if provided.
--! @param      configpath  The path from which the config was loaded.
--!
function TOOL.BuildCPanel(panel, worker, config, name, configpath)

	-- Wait for weapon to be initialized before creating the panel.
	if (worker == nil) then return; end
	local tool = worker:GetOwner():GetTool();

	-- Add config section to editor.
	local systemCategory = vgui.Create("DCollapsibleCategory");
	systemCategory:SetLabel("System");
	systemCategory:SetExpanded(false);
	panel:AddItem(systemCategory);

		-- Print particle button. The particle configuration will be printed to console.
		local clearConfig = vgui.Create("DButton", systemCategory);
		clearConfig:SetText("Reset");
		clearConfig:Dock(TOP);
		function clearConfig:DoClick()
			panel:ClearControls();
			tool.BuildCPanel(panel, worker);
			worker.Particles = {};
		end

	-- Adjust parenting attachment slider.
	panel:AddControl("Slider", { Label = "#tool.3d_particle_system_editor.parent_attachment", Max = 50, Command = "3d_particle_system_editor_parent_attachment" });

	-- New particle text input.
	local entry = vgui.Create("DTextEntry");
	entry:SetValue("New Particle");
	panel:AddItem(entry);

	-- Add particle button.
	local add = panel:Button("Add Particle");
	function add:DoClick()
		GLOBALS_3D_PARTICLE_EDITOR:AddParticlePropertyPanel(worker, panel, entry);
	end

	-- Add config section to editor.
	local configCategory = vgui.Create("DCollapsibleCategory");
	configCategory:SetLabel("Config");
	configCategory:SetExpanded(false);
	panel:AddItem(configCategory);

		-- Generic panel for layout.
		local container = vgui.Create("DPanel", configCategory);
		container:Dock(TOP);
		configCategory:SetContents(container);

			-- Config filename input.
			local configEntry = vgui.Create("DTextEntry", container);
			configEntry:SetValue(name || "New System");
			configEntry:Dock(TOP);

			-- Config filepath input.
			local label = vgui.Create("DLabel", container);
			label:SetText(configpath || "");
			label:SetHeight(0);
			label:SetAlpha(0);
			label:Dock(TOP);

			-- Save particle system button.
			local browser = nil;
			local saveConfig = vgui.Create("DButton", container);
			saveConfig:SetText("Save Particle System");
			saveConfig:Dock(TOP);
			function saveConfig:DoClick()
				if (GLOBALS_3D_PARTICLE_EDITOR:Save(worker, configEntry:GetValue(), browser:GetCurrentFolder())) then
					browser:SetCurrentFolder(browser:GetCurrentFolder());
				end
			end

			-- Print particle button. The particle configuration will be printed to console.
			local printConfig = vgui.Create("DButton", container);
			printConfig:SetText("Print Particle System");
			printConfig:Dock(TOP);
			function printConfig:DoClick()
				print(GLOBALS_3D_PARTICLE_EDITOR:SerializeParticles(worker));
			end

			-- Add file browser for configuration support.
			file.CreateDir("3d_particle_system_editor/");
			browser = vgui.Create("DFileBrowser", container);
			browser:Dock(TOP);
			browser:SetPath("GAME");
			browser:SetBaseFolder("data");
			browser:SetOpen(true);
			browser:SetCurrentFolder("3d_particle_system_editor");
			browser:SetHeight(300);
			function browser:OnSelect(path, sender)
				label:SetText(path);
				configEntry:SetValue(string.Replace(string.Replace(string.match(path, "[^/]+$"), ".lua", ""), ".txt", ""));
			end

			-- Load particle configuration button.
			local loadConfig = vgui.Create("DButton", container);
			loadConfig:SetText("Load Config");
			loadConfig:Dock(TOP);
			function loadConfig:DoClick()

				local filePath = label:GetText();
				if (filePath != nil && filePath != "") then

					-- Call to BuildCPanel to load the configuration.
					local state = file.Read(string.Replace(filePath, "data/", ""));
					panel:ClearControls();
					tool.BuildCPanel(panel, worker, state, string.Replace(string.Replace(string.match(filePath, "[^/]+$"), ".lua", ""), ".txt", ""), filePath);
					worker:GetOwner():PrintMessage(HUD_PRINTTALK, "Loaded " .. filePath);
				end
			end

	-- Load configuration file if provided.
	if (config != nil) then

		-- Deserialize and load particles onto the worker entity for data transfers.
		local particles = GLOBALS_3D_PARTICLE_PARSER:DeserializeParticles(config, worker);

		-- Use data transfer entity to create and load properties into property panel editor.
		for k,v in pairs(particles) do
			entry:SetValue(k);
			GLOBALS_3D_PARTICLE_EDITOR:AddParticlePropertyPanel(worker, panel, entry, true);
		end
	end
end

--!
--! @brief      Debug HUD to show where the particle system is in the world.
--!
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