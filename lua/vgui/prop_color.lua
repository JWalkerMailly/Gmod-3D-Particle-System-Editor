
DEFINE_BASECLASS("DProperty_Generic");

local PANEL = {};

function PANEL:ColorToString(color)
	return math.floor(color.r) .. " " .. math.floor(color.g) .. " " .. math.floor(color.b);
end

function PANEL:ValueChanged(newval, bForce)

	BaseClass.ValueChanged(self, newval, bForce);
	self.ColorValue = newval;
end

function PANEL:Setup(vars)

	-- Fallback value.
	self.ColorValue = "255 255 255";

	BaseClass.Setup(self, vars || {});
	local __SetValue = self.SetValue;

	local btn = self:Add("DButton");
	btn:Dock(LEFT);
	btn:DockMargin(0, 2, 4, 2);
	btn:SetWide(16);
	btn:SetText("");

	btn.Paint = function(sender, w, h)
		local color = string.ToColor(self.ColorValue .. " 255");
		surface.SetDrawColor(color.r, color.g, color.b, 255);
		surface.DrawRect(0, 0, w, h);
		surface.SetDrawColor(25, 25, 25, 200);
		surface.DrawOutlinedRect(0, 0, w, h);
	end

	btn.DoClick = function()

		local color = vgui.Create("DColorCombo", self);
		color:SetupCloseButton(function() CloseDermaMenus(); end);
		color.OnValueChanged = function(col, newcol)
			self.ColorValue = self:ColorToString(newcol);
			__SetValue(self, self.ColorValue);
			BaseClass.ValueChanged(self, self.ColorValue, true);
		end

		local menu = DermaMenu();
		menu:AddPanel(color);
		menu:SetPaintBackground(false);
		menu:Open(gui.MouseX() + 8, gui.MouseY() + 10);
	end

	self.SetValue = function(sender, value)
		self.ColorValue = self:ColorToString(value);
		__SetValue(sender, self.ColorValue);
	end

	self.GetValue = function(sender)
		local color = string.Split(sender.ColorValue, " ");
		return (tonumber(color[1]) || 0) .. " " .. (tonumber(color[2]) || 0) .. " " .. (tonumber(color[3]) || 0);
	end
end

derma.DefineControl("DProperty_Color", "", PANEL, "DProperty_Generic");