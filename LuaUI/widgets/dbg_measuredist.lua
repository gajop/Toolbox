
local versionNumber = "1.0"

function widget:GetInfo()
	return {
		name      = "Measure distance",
		desc      = "Measure distance on surface",
		author    = "Jools",
		date      = "Nov, 2013",
		license   = "All rights reserved",
		layer     = -5,
		enabled   = false
	}
end

local Echo							= Spring.Echo
local AssignMouseCursor				= Spring.AssignMouseCursor
local SetMouseCursor				= Spring.SetMouseCursor
local GetGroundHeight				= Spring.GetGroundHeight
local glColor 						= gl.Color
local glRect						= gl.Rect
local glTexture 					= gl.Texture
local glDepthTest 					= gl.DepthTest
local glBeginEnd 					= gl.BeginEnd
local glPushMatrix 					= gl.PushMatrix
local glPopMatrix 					= gl.PopMatrix
local glTranslate 					= gl.Translate
local glText 						= gl.Text
local glLineWidth					= gl.LineWidth
local glLineStipple            		= gl.LineStipple
local glVertex 						= gl.Vertex
local GL_LINE_STRIP            		= GL.LINE_STRIP
local TraceScreenRay				= Spring.TraceScreenRay
local TextDraw            		 	= fontHandler.Draw
local max							= math.max
local min							= math.min

local vsx, vsy 						= gl.GetViewSizes()
local px							= 3*vsx/4
local py							= 3*vsy/4
local sizex							= 140
local sizey							= 24
local th							= 14
local Button = {}
Button["measure"] = {}
local pos0 = {}
local pos1 = {}

local function initButtons()
	Button["measure"]["x0"] = px
	Button["measure"]["x1"] = px + sizex
	Button["measure"]["y0"] = py
	Button["measure"]["y1"] = py + sizey
end

local function round(num, idp)
	return string.format("%." .. (idp or 0) .. "f", num)
end
	
function widget:Initialize()
	AssignMouseCursor('Select', 'cursorselect', true, false)
	AssignMouseCursor('Normal', 'cursornormal', true, false)
	initButtons()
end

local function IsOnButton(x, y, BLcornerX, BLcornerY,TRcornerX,TRcornerY)
	if BLcornerX == nil then return false end
	-- check if the mouse is in a rectangle

	return x >= BLcornerX and x <= TRcornerX
	                      and y >= BLcornerY
	                      and y <= TRcornerY
end

function widget:DrawScreen()
	if Spring.IsGUIHidden() then return end
	
	glColor(0, 0, 0, 0.4)
	glRect(Button["measure"]["x0"],Button["measure"]["y0"], Button["measure"]["x1"], Button["measure"]["y1"])
	glColor(1, 1, 1, 1)
		
	-- Highlight
	glColor(0.8, 0.8, 0.2, 0.4)
	if Button["measure"]["mouse"] then
		glRect(Button["measure"]["x0"],Button["measure"]["y0"], Button["measure"]["x1"], Button["measure"]["y1"])
	end
	-- button selected
	glColor(0.8, 0.8, 0.8, 0.4)
	if Button["measure"]["On"] then
		glRect(Button["measure"]["x0"],Button["measure"]["y0"], Button["measure"]["x1"], Button["measure"]["y1"])
	end	
		
	if pos0 and #pos0 > 0 and pos1 and #pos1 > 0 then
		local x0,y0,z0 = pos0[1],pos0[2],pos0[3]
		local x1,y1,z1 = pos1[1],pos1[2],pos1[3]
		local dist = ((x1-x0)*(x1-x0)+(y1-y0)*(y1-y0)+(z1-z0)*(z1-z0))^0.5
		local label = tostring(round(dist,1))
		if Button["measure"]["On"] then
			glColor(0, 0, 0, 1)
		else
			glColor(1, 1, 1, 1)
		end
		
		glText("Distance = " .. label, Button["measure"]["x0"]+10,Button["measure"]["y0"]+8, th, 'x')
		glColor(0.8, 0.2, 0.2, 0.8)
		local offset = 30
		local i,j,k = (x1-x0)/dist,(y1-y0)/dist,(z1-z0)/dist	-- unit vector i,j,k
		
		local mx,my = Spring.WorldToScreenCoords(x1,y1,z1)
		--Echo(mx,my,i,k)
		mx = mx+offset*i
		my = my-offset*k
		--Echo(mx,my)
		glText(label, mx,my,th,'vc')
	else
		if Button["measure"]["On"] then
			glColor(0, 0, 0, 1)
		else
			glColor(1, 1, 1, 1)
		end
		glText("Measure distance", Button["measure"]["x0"]+10,Button["measure"]["y0"]+8, th, 'x')
	end	

	glColor(1, 1, 1, 1)
end

function widget:DrawWorld()
	if Spring.IsGUIHidden() then return end

	if pos0 and #pos0 > 0 and pos1 and #pos1 > 0 then
		
		
		if Button["measure"]["active"]then
			glColor(0.8, 0.2, 0.2, 1.0)
			glLineWidth (4.0)
		else
			glColor(0.8, 0.2, 0.2, 0.7)
			glLineWidth (2.0)
		end
		
		local function Line(a, b)
			glVertex(a[1], a[2], a[3])
			glVertex(b[1], b[2], b[3])
		end

		local function DrawLine(a, b)
			glLineStipple(false)
			glBeginEnd(GL_LINE_STRIP, Line, a, b)
			glLineStipple(false)
		end
		
		DrawLine(pos0,pos1)
	end
	glColor(1, 1, 1, 1)
end

function widget:IsAbove(mx,my)	
	Button["measure"]["mouse"] = false
	if IsOnButton(mx,my,Button["measure"]["x0"],Button["measure"]["y0"],Button["measure"]["x1"],Button["measure"]["y1"]) then		
		Button["measure"]["mouse"] = true
	end	
end

function widget:DefaultCommand(type, uID)
	if Button["measure"]["On"] then
		SetMouseCursor('Select')
		return true
	end
end

function widget:MousePress(mx, my, mButton)
	if (mButton == 2 or mButton == 3) and mx < px + sizex then
		if mx >= px and my >= py and my < py + sizey then
			-- Dragging
			return true
		end
	elseif mButton == 1 then
		if IsOnButton(mx,my,Button["measure"]["x0"],Button["measure"]["y0"],Button["measure"]["x1"],Button["measure"]["y1"]) then
			Button["measure"]["On"] = true
			return false
		else
			if Button["measure"]["On"] then
				Button["measure"]["active"] = true
				local _, pos = TraceScreenRay(mx, my, true)
				if not pos then return end
				
				local x,y,z = pos[1],pos[2],pos[3]
				
				pos0 = {x,y,z}
				return true -- make mouserelease catch event only in this case
			end
		end
		return false
	end
	initButtons()
end

function widget:MouseRelease(mx, my, mbutton)
	Button["measure"]["active"] = false
	return false
end

function widget:KeyPress(key, mods, isRepeat)
	if (key == 0x01B) and (not isRepeat) and (not mods.ctrl) and (not mods.shift) then -- KEY = ESC
		Button["measure"]["On"] = false
		pos0 = {}
		pos1 = {}
	end
end

function widget:MouseMove(mx, my, dx, dy, mButton)
    -- Dragging
    if mButton == 2 or mButton == 3 then
		px = max(0, min(px+dx, vsx-sizex))	--prevent moving off screen
		py = max(0, min(py+dy, vsy-sizey))
		initButtons()
	elseif mButton == 1 and Button["measure"]["On"] then
		if pos0 and #pos0 > 0 then
			local _, pos = TraceScreenRay(mx, my, true)
			if not pos then return end
			
			local x,y,z = pos[1],pos[2],pos[3]
			pos1 = {x,y,z}
		end
    end	
end

function widget:GetConfigData(data)      -- save
	local vsx, vsy = gl.GetViewSizes()
	return {
			vsx                = vsx,
			vsy                = vsy,
			px         = px,
			py         = py,
		}
	end

function widget:SetConfigData(data)      -- load
	vsx					= data.vsx or vsx
	vsy 				= data.vsy or vsy
	px         	= data.px or px
	py         	= data.py or py
end

