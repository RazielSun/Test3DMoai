
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
			contentRect = { 0, -300, halfW, 1100 },
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
local HORIZONT = 100 --95

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
end

function MapView:createContent()
	local layer = self.layer

	local plane = self:create( 'Plane.mesh', 'ground.png' )
	plane:setLoc( 0, 0, -750 )
	layer:insertProp ( plane )

	local tree = self:create( 'tree_a.mesh', 'trees.png' )
	tree:setLoc( 100, 10, -800 )
	layer:insertProp ( tree )

	local tree2 = self:create( 'tree_a.mesh', 'trees.png' )
	tree2:setLoc( -150, 10, -1100 )
	layer:insertProp ( tree2 )

	local rock = self:create( 'rock_a.mesh', 'rocks.png' )
	rock:setLoc( -120, 10, -600 )
	layer:insertProp ( rock )

	local rock2 = self:create( 'rock_a.mesh', 'rocks.png' )
	rock2:setLoc( 170, 10, -1200 )
	layer:insertProp ( rock2 )

	local prop = self:create( 'MyBoxy.mesh', 'moai.png' )
	prop:setLoc( -100, 16, -350 )
	layer:insertProp ( prop )

	local prop = self:create( 'MyBoxy.mesh', 'moai.png' )
	prop:setLoc( 130, 16, -600 )
	layer:insertProp ( prop )

	self._camera:setLoc( 0, -HORIZONT, 0 ) --226
	-- self._camera:setRot( -15, 0, 0 )
	-- self._camera:setOrtho( true )
	self._camPos = { self._camera:getLoc() }
end

function MapView:createPoints()
	local layer = self.layer

	local point = self:create( 'Cylinder.mesh', 'points.png' )
	point:setLoc( 0, 0, -220 )
	point.isp = true
	layer:insertProp ( point )

	local point2 = self:create( 'Cylinder.mesh', 'points.png' )
	point2:setLoc( 20, 0, -400 )
	point2.isp = true
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
	-- print("MapView setLoc", cx, cy, cz, "to:", x, y, z)
	self._camera:setLoc( cx, cy, y )
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
function MapView:calc( dx, dy, dz )
	local k1 = (- K_VALUE)
	local k2 = dy / dz
	local A = k1
	local B = - k2
	local C = (- DISTANCE) * k2 + HORIZONT
	local D = B * B - 4 * A * C
	if D > 0 then
		local a = 2 * A
		local b = -B
		local sq = math.sqrt(D)
		local x1 = (b+sq) / a
		local x2 = (b-sq) / a
		local fx = math.max(x1, x2)
		return true, fx
	else
		return false, 0
	end
end

function MapView:onInputEvent( event )
	local handled = false

	handled = self.scrollArea:handleInputEvent( event )

	if InputEvent.isPointed( event ) then
	    if not handled then
	    	local vx, vy = self.scrollArea.layer:wndToWorld( event.wx, event.wy )

	    	if vy < HORIZONT then
	    		local x, y, z, dx, dy, dz = self.layer:wndToWorldRay( event.wx, event.wy )
		    	local success, fx = self:calc( dx, dy, dz )
		    	local cx, cy, cz = self._camera:getLoc()

	    		local x, y, z, dirX, dirY, dirZ = vx, 300, cz+DISTANCE+fx, 0, -1, 0

	    		local partition = self.layer:getPartition()
	    		local result = { partition:propListForRay( x, y, z, dirX, dirY, dirZ, defaultSortMode ) }
	    		for i, elem in ipairs(result) do
	    			if elem.isp then
	    				handled = elem
	    			end
	    			if handled then
			    		break
			    	end
	    		end
	    	end

	    	for _, prop in ipairs(self.active) do
	    		prop:setScl( 1, 1, 1 )
	    	end

	    	if handled then
	    		handled:setScl( 1.2, 1, 1.2 )
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
