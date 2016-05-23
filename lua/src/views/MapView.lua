
local Entity = require("entity.Entity")
local InputEvent = require("input.InputEvent")

local ScrollArea = require("views.ScrollArea")


local vsh = [=[
uniform mat4 world;
uniform mat4 viewProj;
uniform float horizont;
uniform float scalar;

attribute vec4 position;
attribute vec2 uv;
attribute vec4 color;

varying vec4 colorVarying;
varying vec2 uvVarying;

void main () {
	vec4 model = position * world;
	float dist = model.z - horizont;
	model.y -= scalar * dist * dist;
    gl_Position = model * viewProj;
	uvVarying = uv;
    colorVarying = color;
}
]=]

local fsh = [=[
varying LOWP vec4 colorVarying;
varying MEDP vec2 uvVarying;

uniform sampler2D sampler;

void main() {
	gl_FragColor = texture2D ( sampler, uvVarying ) * colorVarying;
}
]=]

---------------------------------------------------------------------------------
--
-- @type MapView
--
---------------------------------------------------------------------------------

local MapView = Class( Entity, "MapView" )

function MapView:init()
	Entity.init(self)

	self._viewport = MOAIViewport.new()
	self._viewport:setSize(App.screenWidth, App.screenHeight)
    self._viewport:setScale(App.viewWidth, App.viewHeight)

	self._camera = MOAICamera.new()

	self.layer = MOAILayer.new()
	self.layer:setCamera( self._camera )
	self.layer:setViewport( self._viewport )
	self.layer:setPartitionCull2D ( false )
	self.active = {}

	self:createShaderProgram()
	self:createShader()
	self:initScrollArea()
end

function MapView:initScrollArea()
	local halfW, halfH = 0.5*App.viewWidth, 0.5*App.viewHeight

	local scrollArea = self:add(
		ScrollArea( {
			direction = ScrollArea.DIRECTIONS.VERTICAL,
			target = self,
			boundRect = { -halfW, -halfH, halfW, halfH },
			contentRect = { 0, 0, halfW, 1424 },
		} )
	)

	self.scrollArea = scrollArea
end

function MapView:createShaderProgram()
	local program = MOAIShaderProgram.new ()

	program:setVertexAttribute ( 1, 'position' )
	program:setVertexAttribute ( 2, 'uv' )
	program:setVertexAttribute ( 3, 'color' )

	program:reserveUniforms ( 4 )
	program:declareUniform ( 1, 'viewProj', MOAIShaderProgram.UNIFORM_MATRIX_F4 )
	program:declareUniform ( 2, 'world', MOAIShaderProgram.UNIFORM_MATRIX_F4 )
	program:declareUniform ( 3, 'horizont', MOAIShaderProgram.UNIFORM_FLOAT )
	program:declareUniform ( 4, 'scalar', MOAIShaderProgram.UNIFORM_FLOAT )

	program:reserveGlobals ( 2 )
	program:setGlobal ( 1, 1, MOAIShaderProgram.GLOBAL_VIEW_PROJ )
	program:setGlobal ( 2, 2, MOAIShaderProgram.GLOBAL_WORLD )	

	program:load ( vsh, fsh )

	self.program = program
end

function MapView:createShader()
	local shader = MOAIShader.new ()
	shader:setProgram ( self.program )
	self.shader = shader
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
local DISTANCE = -700
local K_VALUE = 0.0008
local HORIZONT = 0 --95

function MapView:onLoad()
	self:createContent()
	self:createPoints()

	self.shader:setAttr( 4, K_VALUE )

	self.znode = MOAIScriptNode.new()
	self.znode:reserveAttrs( 1 )
	self.znode:setCallback( function(node)
		local value = node:getAttr( 1 )
		self.shader:setAttr(3, value+DISTANCE)
	end )
	self.znode:setAttrLink( 1, self._camera, MOAITransform.ATTR_Z_LOC )

	self.rect = {-300,-300,300,300}
	self.rect2 = {-300,-300,300,300}

	local scriptDeck = MOAIScriptDeck.new ()
	local hW, hH = App.viewWidth*0.5, App.viewHeight*0.5
	scriptDeck:setRect ( -hW, -hH, hW, hH )
	scriptDeck:setDrawCallback ( function (index, xOff, yOff, xFlip, yFlip)
		MOAIGfxDevice.setPenColor ( 1, 0, 0, 1 )
		MOAIGfxDevice.setPenWidth ( 2 )
		MOAIDraw.drawRect( unpack(self.rect) )
		MOAIGfxDevice.setPenColor ( 0, 0, 1, 1 )
		MOAIDraw.drawRect( unpack(self.rect2) )
		MOAIGfxDevice.setPenColor ( 0, 1, 0, 1 )
		-- MOAIDraw.drawLine( -hW, HORIZONT, hW, HORIZONT )
		local h = -26
		MOAIDraw.drawLine( -hW, h, hW, h )
	end )

	local prop = MOAIProp2D.new ()
	prop:setDeck ( scriptDeck )
	self.scrollArea.layer:insertProp ( prop )

	RenderMgr:addChild(self.scrollArea.layer)

	local bounds1 = self:getPointBounds(1)
	local bounds2 = self:getPointBounds(2)

	self.rect[1] = bounds1[1]
	self.rect[3] = bounds1[3]

	self.rect2[1] = bounds2[1]
	self.rect2[3] = bounds2[3]

	local halfH = App.viewHeight * 0.5
	local cx, cy, cz = self._camera:getLoc()

	local startValue = 3
	local cdy0 = startValue
	local cdy1 = startValue
	local cdx0 = startValue
	local cdx1 = startValue

	-- print("viewHeight:",App.viewHeight)
	self.A = -0.002585
	self.B = -0.314687

	local HH = HORIZONT + halfH
	local PP = 108
	local SC = HH/PP
	local mH = -476
	local f0 = mH - (-250 * SC)
	local f1 = HH * HH - PP * PP * SC
	self.A = f0/f1
	self.B = (mH - self.A * HH * HH) / HH

	print("A B", self.A, self.B)

	for i = 0, HH do
		local z = self:getZ( i )
		local ff = i - halfH
		print(ff, z)
		local dy0 = math.abs(z+cz-bounds1[2])
		local dy1 = math.abs(z+cz-bounds1[4])
		if dy0 < cdy0 then cdy0=dy0 ; self.rect[2] = ff end
		if dy1 < cdy1 then cdy1=dy1 ; self.rect[4] = ff end

		local dx0 = math.abs(z+cz-bounds2[2])
		local dx1 = math.abs(z+cz-bounds2[4])
		if dx0 < cdx0 then cdx0=dx0 ; self.rect2[2] = ff end
		if dx1 < cdx1 then cdx1=dx1 ; self.rect2[4] = ff end
	end
end

function MapView:createContent()
	local layer = self.layer

	local plane = self:create( 'Plane.mesh', 'ground.png' )
	plane:setLoc( 0, 0, -750 )
	layer:insertProp ( plane )

	local tree = self:create( 'tree_a.mesh', 'trees.png' )
	tree:setLoc( 100, 10, -1000 )
	layer:insertProp ( tree )

	local tree2 = self:create( 'tree_a.mesh', 'trees.png' )
	tree2:setLoc( -150, 10, -1400 )
	layer:insertProp ( tree2 )

	local rock = self:create( 'rock_a.mesh', 'rocks.png' )
	rock:setLoc( -120, 10, -700 )
	layer:insertProp ( rock )

	local rock2 = self:create( 'rock_a.mesh', 'rocks.png' )
	rock2:setLoc( 170, 10, -1600 )
	layer:insertProp ( rock2 )

	local prop = self:create( 'MyBoxy.mesh', 'moai.png' )
	prop:setLoc( -20, 16, -850 )
	layer:insertProp ( prop )

	local prop = self:create( 'MyBoxy.mesh', 'moai.png' )
	prop:setLoc( 130, 16, -750 )
	layer:insertProp ( prop )

	self._camera:setLoc( 0, 0, 226 )
	-- self._camera:setRot( -15, 0, 0 )
	self._camPos = { self._camera:getLoc() }
end

function MapView:createPoints()
	local layer = self.layer

	local point = self:create( 'Cylinder.mesh', 'points.png' )
	point:setLoc( 0, 10, -60 )
	layer:insertProp ( point )

	local point2 = self:create( 'Cylinder.mesh', 'points.png' )
	point2:setLoc( 50, 10, -300 )
	layer:insertProp ( point2 )

	self.points = { point, point2 }
end

function MapView:create( meshName, spriteName )
	local base = 'assets/3ds/'
	local file = MOAIFileSystem.loadFile( base .. meshName )
    local mesh = assert( loadstring(file) )()

    mesh:setTexture ( base .. spriteName )
    mesh:setShader ( self.shader )

    local prop = MOAIProp.new ()
	prop:setDeck ( mesh )
	prop:setDepthTest( MOAIGraphicsProp.DEPTH_TEST_LESS )
	prop:setCullMode ( MOAIGraphicsProp.CULL_BACK )
	prop.name = spriteName

	table.insert( self.active, prop )

	return prop
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
function MapView:setLoc( x, y, z )
	local cx, cy, cz = unpack(self._camPos)
	self._camera:setLoc( cx, cy, y )
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

function MapView:calcZ( value )
	local halfH = App.viewHeight * 0.5
	local vz = value + halfH
	local nz = vz / (HORIZONT + halfH)
	local z = nz * DISTANCE

	local dist = DISTANCE - z

	return self:calcViewY( nz )
end

-- local scl = { 0, 0 }
-- local scl = { 1, 1 }
-- local scl = { 0.55, 0.11 }
local scl = { 0, 0 }

function MapView:calcViewY( t )
	local y0 = 0
	local sx, sy = unpack(scl)
	local y1 = DISTANCE * sx
	local y2 = DISTANCE * sy
	local y3 = DISTANCE * 1.0
	local y = self:bezier( t, y0, y1, y2, y3 )
	return y
end

function MapView:bezier( t, v0, v1, v2, v3 )
	local value = (1-t)*(1-t)*(1-t)*v0 + 3*t*(1-t)*(1-t)*v1 + 3*t*t*(1-t)*v2 + t*t*t*v3
	return value
end

function MapView:getPointBounds( num )
	local point = self.points[num]
	local minX, minY, minZ, maxX, maxY, maxZ = point:getBounds()
	local x, y, z = point:getLoc()
	return { minX+x, minZ+z, maxX+x, maxZ+z }
end

function MapView:getZ( viewY )
	return self.A * viewY * viewY + self.B * viewY
end

function MapView:onInputEvent( event )
	local handled = false

	handled = self.scrollArea:handleInputEvent( event )

	if InputEvent.isPointed( event ) then
	    if not handled then
	    	local vx, vy = self.scrollArea.layer:wndToWorld( event.wx, event.wy )

	    	if vy < HORIZONT then
	    		local cx, cy, cz = self._camera:getLoc()
	    		local x, y, z, dirX, dirY, dirZ = vx, 300, self:getZ(vy+App.viewHeight*0.5)+cz, 0, -1, 0

	    		local partition = self.layer:getPartition()
	    		local result = { partition:propListForRay( x, y, z, dirX, dirY, dirZ, defaultSortMode ) }
	    		for i, elem in ipairs(result) do
	    			-- print("elem:", elem, elem.name, elem:getLoc())
	    			handled = elem
	    			if handled then
			    		break
			    	end
	    		end
	    	end

	    	for _, prop in ipairs(self.active) do
	    		prop:setScl( 1, 1, 1 )
	    	end

	    	if handled then
	    		handled:setScl( 1.2, 1, 1 )
	    	end
	    	-- local originX, originY, originZ, directionX, directionY, directionZ = self.layer:wndToWorldRay (  event.wx, event.wy )
	    	-- print("wndToWorld:", originX, originY, originZ, directionX, directionY, directionZ)
			-- local result = { partition:propListForRay( originX, originY, originZ, directionX, directionY, directionZ, defaultSortMode ) }
	    	-- for i, elem in ipairs(result) do
	    		-- print("elem:", elem, elem.name)
	    		-- if elem.entity then
		    	-- 	handled = elem.entity:handleInputEvent( event )
		    	-- end
		    	-- if handled then
		    	-- 	break
		    	-- end
	    	-- end
	    end
	end

	return handled
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

return MapView
