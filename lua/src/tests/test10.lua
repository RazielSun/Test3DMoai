
local vsh = [=[
uniform mat4 world;
uniform mat4 viewProj;
uniform float horizont;

attribute vec4 position;
attribute vec2 uv;
attribute vec4 color;

varying vec4 colorVarying;
varying vec2 uvVarying;

void main () {
	vec4 model = position * world;
	float dist = model.z - horizont;
	if (dist < 0.0) {
		dist = 0.0;
	}
	model.y -= dist * dist * 0.0006;
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

local sizeW, sizeH, sizeD = 6, 0.2, 10

local M_ = {}

function M_:setup( layer )
	self:createShaderProgram()
	self:createShader()

	local prop2 = self:loadPlane()
	prop2:setLoc( 0, 0, 0 )
	layer:insertProp ( prop2 )

	local prop = self:loadMesh()
	prop:setLoc( 0, 120, -200 )
	layer:insertProp ( prop )

	local camera = MOAICamera.new ()
	camera:setLoc( 0, 500, 3000 )
	camera:setRot( -30, 0, 0 )
	-- camera:lookAt( 0, 0, 500 )
	-- camera:setOrtho( true )
	layer:setCamera ( camera )

	local dprop = MOAIProp.new()
	local cx, cy, cz = camera:getLoc()
	dprop:setLoc( cx, cy, cz-2000 )
	-- dprop:setAttrLink( MOAIProp.INHERIT_TRANSFORM, camera, MOAIProp.TRANSFORM_TRAIT )

	-- self.shader:setAttr(3, 0.0)
	self.shader:setAttrLink( 3, dprop, MOAITransform.ATTR_Z_LOC )

	self.znode = MOAIScriptNode.new()
	self.znode:reserveAttrs( 1 )
	self.znode:setCallback( function(node)
		local value = node:getAttr( 1 )
		print("update:", value)
	end )

	-- self.znode:setAttrLink( 1, dprop, MOAITransform.ATTR_Z_LOC )

	camera:seekLoc( cx, cy, -cz, 10 )
	dprop:seekLoc( cx, cy, -cz-2000, 10 )
end

function M_:createShaderProgram()
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

function M_:createShader()
	local shader = MOAIShader.new ()
	shader:setProgram ( self.program )
	self.shader = shader
end

function M_:loadMesh()
	local file = MOAIFileSystem.loadFile( 'assets/3ds/MyBoxy.mesh' )
    local mesh = assert( loadstring(file) )()

    print('mesh', mesh, mesh.textureName)

    mesh:setTexture ( "assets/3ds/moai.png" )
    mesh:setShader ( self.shader )

    local prop = MOAIProp.new ()
	prop:setDeck ( mesh )
	prop:setCullMode ( MOAIGraphicsProp.CULL_BACK )
	
	return prop
end

function M_:loadPlane()
	local file = MOAIFileSystem.loadFile( 'assets/3ds/Plane.mesh' )
    local mesh = assert( loadstring(file) )()

    print('mesh', mesh, mesh.textureName)

    mesh:setTexture ( "assets/3ds/moai.png" )
    mesh:setShader ( self.shader )

    local prop = MOAIProp.new ()
	prop:setDeck ( mesh )
	prop:setCullMode ( MOAIGraphicsProp.CULL_BACK )
	
	return prop
end

return M_