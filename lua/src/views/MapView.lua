
local Entity = require("entity.Entity")
local InputEvent = require("input.InputEvent")

local ScrollArea = require("views.ScrollArea")


local vsh = [=[
uniform mat4 world;
uniform mat4 viewProj;
uniform float horizont;

attribute vec4 position;
attribute vec2 uv;
attribute vec4 color;

varying vec4 colorVarying;
varying vec2 uvVarying;

const float K = 0.0006;

void main () {
	vec4 model = position * world;
	float dist = model.z - horizont;
	if (dist >= 0.0) {
		model.y -= K * dist * dist;
	}

	vec4 pos = model * viewProj;

    gl_Position = pos;
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

	-- self.active = {}

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

	program:reserveUniforms ( 3 )
	program:declareUniform ( 1, 'viewProj', MOAIShaderProgram.UNIFORM_MATRIX_F4 )
	program:declareUniform ( 2, 'world', MOAIShaderProgram.UNIFORM_MATRIX_F4 )
	program:declareUniform ( 3, 'horizont', MOAIShaderProgram.UNIFORM_FLOAT )

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
function MapView:onLoad()
	self:createContent()
	self:createPoints()

	self.znode = MOAIScriptNode.new()
	self.znode:reserveAttrs( 1 )
	self.znode:setCallback( function(node)
		local value = node:getAttr( 1 )
		self.shader:setAttr(3, value-700)
	end )
	self.znode:setAttrLink( 1, self._camera, MOAITransform.ATTR_Z_LOC )
end

function MapView:createContent()
	local layer = self.layer

	local plane = self:create( 'Plane.mesh', 'ground.png' )
	plane:setLoc( 0, 0, -1100 )
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

	self._camera:setLoc( 0, 100, -300 )
	self._camera:setRot( -15, 0, 0 )
	self._camPos = { self._camera:getLoc() }
end

function MapView:createPoints()
	local layer = self.layer

	local point = self:create( 'Cylinder.mesh', 'points.png' )
	point:setLoc( 0, 10, -550 )
	layer:insertProp ( point )
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
	
	return prop
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
function MapView:setLoc( x, y, z )
	local cx, cy, cz = unpack(self._camPos)
	self._camera:setLoc( cx, cy, y )
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
function MapView:onInputEvent( event )
	local handled = false

	handled = self.scrollArea:handleInputEvent( event )

	if InputEvent.isPointed( event ) then
	    if not handled then
	    	event.x, event.y = self.layer:wndToWorld( event.wx, event.wy )
	    	local partition = self.layer:getPartition()
			local result = { partition:propListForPoint( event.x, event.y, 0, defaultSortMode ) }
	    	for i, elem in ipairs(result) do
	    		if elem.entity then
		    		handled = elem.entity:handleInputEvent( event )
		    	end
		    	if handled then
		    		break
		    	end
	    	end
	    end
	end

	return handled
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

return MapView
