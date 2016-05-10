
local vsh = [=[
uniform float viewWidth;
uniform float viewHeight;

uniform mat4 world;
uniform mat4 worldInverse;

uniform mat4 worldView;
uniform mat4 worldViewInverse;

uniform mat4 viewProj;
uniform mat4 worldViewProj;

attribute vec4 position;
attribute vec2 uv;
attribute vec4 color;

varying vec4 colorVarying;
varying vec2 uvVarying;

const float HORIZON = 0.0;
const float SPREAD = 0.0;
const float ATTENUATE = 0.0006;

void main () {
	vec4 pos = position * worldViewProj;

    gl_Position = pos;
	uvVarying = uv;

	vec4 t = position * world;
	float dist = max(0.0, abs(HORIZON - t.z) - SPREAD);
	t.y -= dist * dist * ATTENUATE;
	// t.xyz = vec4(t * worldInverse).xyz;

	gl_Position = t * viewProj;

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

local M_ = {}

function M_:setup( layer )
	self:createShaderProgram()
	self:createShader()

	local prop2 = self:loadPlane()
	prop2:setLoc( 0, 0, 0 )
	layer:insertProp ( prop2 )

	local prop = self:loadMesh()
	prop:setLoc( 0, 128, -200 )
	layer:insertProp ( prop )

	local camera = MOAICamera.new ()
	-- camera:setLoc( 0, 1500, 3000 )
	-- camera:lookAt( 0, 0, 500 )
	camera:setOrtho( false )
	camera:setLoc( 0, 1600, 500 )
	camera:setRot( -90, 0, 0 )
	-- camera:lookAt( 0, 0, 0 )
	
	layer:setCamera ( camera )

	camera:seekLoc( 0, 1600, -1000, 10.0 )
end

function M_:createShaderProgram()
	local program = MOAIShaderProgram.new ()

	program:setVertexAttribute ( 1, 'position' )
	program:setVertexAttribute ( 2, 'uv' )
	program:setVertexAttribute ( 3, 'color' )

	program:reserveUniforms ( 8 )
	program:declareUniform ( 1, 'viewProj', MOAIShaderProgram.UNIFORM_MATRIX_F4 )
	program:declareUniform ( 2, 'viewWidth', MOAIShaderProgram.UNIFORM_FLOAT )
	program:declareUniform ( 3, 'viewHeight', MOAIShaderProgram.UNIFORM_FLOAT )
	program:declareUniform ( 4, 'worldInverse', MOAIShaderProgram.UNIFORM_MATRIX_F4 )
	program:declareUniform ( 5, 'worldView', MOAIShaderProgram.UNIFORM_MATRIX_F4 )
	program:declareUniform ( 6, 'worldViewInverse', MOAIShaderProgram.UNIFORM_MATRIX_F4 )
	program:declareUniform ( 7, 'worldViewProj', MOAIShaderProgram.UNIFORM_MATRIX_F4 )
	program:declareUniform ( 8, 'world', MOAIShaderProgram.UNIFORM_MATRIX_F4 )
	
	program:reserveGlobals ( 8 )
	program:setGlobal ( 1, 1, MOAIShaderProgram.GLOBAL_VIEW_PROJ )
	program:setGlobal ( 2, 2, MOAIShaderProgram.GLOBAL_VIEW_WIDTH )
	program:setGlobal ( 3, 3, MOAIShaderProgram.GLOBAL_VIEW_HEIGHT )
	program:setGlobal ( 4, 4, MOAIShaderProgram.GLOBAL_WORLD_INVERSE )
	program:setGlobal ( 5, 5, MOAIShaderProgram.GLOBAL_WORLD_VIEW )
	program:setGlobal ( 6, 6, MOAIShaderProgram.GLOBAL_WORLD_VIEW_INVERSE )
	program:setGlobal ( 7, 7, MOAIShaderProgram.GLOBAL_WORLD_VIEW_PROJ )
	program:setGlobal ( 8, 8, MOAIShaderProgram.GLOBAL_WORLD )

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
