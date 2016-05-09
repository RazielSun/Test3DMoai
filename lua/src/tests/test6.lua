
local vsh = [=[
uniform mat4 transform;

attribute vec4 position;
attribute vec2 uv;
attribute vec4 color;

varying vec4 colorVarying;
varying vec2 uvVarying;

void main () {
    gl_Position = position * transform;
	uvVarying = uv;
    colorVarying = color;
}
]=]

local fsh = [=[
varying LOWP vec4 colorVarying;
varying MEDP vec2 uvVarying;

uniform sampler2D sampler0;
uniform sampler2D sampler1;
uniform sampler2D sampler2;

void main() {
	// from moai.png
	vec4 color0 = texture2D( sampler0, uvVarying );

	// from numbers.png
	vec4 color1 = texture2D( sampler1, uvVarying );

	// from mask.png and get alpha channel
	float mask = texture2D( sampler2, uvVarying ).a;

	// mix color texture
	gl_FragColor = mix(color0, color1, mask) * colorVarying;
}
]=]

local sizeW, sizeH, sizeD = 6, 1, 10

local M_ = {}

function M_:setup( layer )
	self:createShaderProgram()
	self:createShader()
	self:createMulti()

	local prop2 = self:addMyMesh()
	prop2:setLoc( 0, 0, 0 )
	layer:insertProp ( prop2 )

	local prop = self:loadMesh()
	prop:setLoc( 0, 0, -200 )
	layer:insertProp ( prop )

	local camera = MOAICamera.new ()
	camera:setLoc( 0, 500, 1000 )
	camera:lookAt( 0, 0, 500 )
	camera:setOrtho( false )
	layer:setCamera ( camera )
end

function M_:createShaderProgram()
	local program = MOAIShaderProgram.new ()

	program:setVertexAttribute ( 1, 'position' )
	program:setVertexAttribute ( 2, 'uv' )
	program:setVertexAttribute ( 3, 'color' )

	program:reserveUniforms ( 4 )
	program:declareUniform ( 1, 'transform', MOAIShaderProgram.UNIFORM_MATRIX_F4 )
	program:declareUniformSampler ( 2, 'sampler0', 1 )
	program:declareUniformSampler ( 3, 'sampler1', 2 )
	program:declareUniformSampler ( 4, 'sampler2', 3 )

	program:reserveGlobals ( 1 )
	program:setGlobal ( 1, 1, MOAIShaderProgram.GLOBAL_WORLD_VIEW_PROJ ) -- GLOBAL_WORLD_VIEW_PROJ

	program:load ( vsh, fsh )

	self.program = program
end

function M_:createShader()
	local shader = MOAIShader.new ()
	shader:setProgram ( self.program )
	self.shader = shader
end

function M_:createMulti()
	local multitexture = MOAIMultiTexture.new ()
	multitexture:reserve ( 3 )

	local texture1 = MOAITexture.new ()
	texture1:load ( "assets/3ds/moai.png" )
	multitexture:setTexture ( 1, texture1 )

	local texture2 = MOAITexture.new ()
	texture2:load ( "assets/3ds/numbers.png" )
	-- texture2:setWrap ( true )
	multitexture:setTexture ( 2, texture2 )

	local texture3 = MOAITexture.new ()
	texture3:load ( "assets/3ds/mask.png" )
	multitexture:setTexture ( 3, texture3 )

	self.multi = multitexture
end

function M_:loadMesh()
	local file = MOAIFileSystem.loadFile( 'assets/3ds/MyBoxy.mesh' )
    local mesh = assert( loadstring(file) )()

    print('mesh', mesh, mesh.textureName)

    mesh:setTexture ( self.multi )
    mesh:setShader ( self.shader )

    local prop = MOAIProp.new ()
	prop:setDeck ( mesh )
	prop:setCullMode ( MOAIGraphicsProp.CULL_BACK )
	
	return prop
end

function M_:addMyMesh()
	-- default
	local prop = MOAIProp.new()
	local mesh = self:createMesh()

	prop:setDeck( mesh )	
	prop:setCullMode ( MOAIGraphicsProp.CULL_BACK )
	
	return prop
end

function M_:createMesh()
	local vertexFormat = MOAIVertexFormat.new()
	vertexFormat:declareCoord( 1, MOAIVertexFormat.GL_FLOAT, 3 )
	vertexFormat:declareUV( 2, MOAIVertexFormat.GL_FLOAT, 2 )
	vertexFormat:declareColor( 3, MOAIVertexFormat.GL_UNSIGNED_BYTE )

	local vbo = MOAIVertexBuffer.new ()
	vbo:reserve ( 36 * vertexFormat:getVertexSize ())

	local size = 256
	local vertexes = {}

	local addControlPoint = function( x, y, z )
		table.insert( vertexes, { x*size, y*size, z*size } )
	end

	addControlPoint( 0.5*sizeW, 0.5*sizeH, 0.5*sizeD ) -- 0 +
	addControlPoint( 0.5*sizeW, 0.5*sizeH, -0.5*sizeD ) -- 1 +
	addControlPoint( 0.5*sizeW, -0.5*sizeH, 0.5*sizeD ) -- 2 +
	addControlPoint( 0.5*sizeW, -0.5*sizeH, -0.5*sizeD ) -- 3 +
	addControlPoint( -0.5*sizeW, 0.5*sizeH, -0.5*sizeD ) -- 4 +
	addControlPoint( -0.5*sizeW, 0.5*sizeH, 0.5*sizeD ) -- 5 +
	addControlPoint( -0.5*sizeW, -0.5*sizeH, -0.5*sizeD ) -- 6 +
	addControlPoint( -0.5*sizeW, -0.5*sizeH, 0.5*sizeD ) -- 7 +

	local normals = {}
	local addNormal = function( x, y, z )
		table.insert(normals, {x,y,z})
	end

	addNormal( 1, 0, 0 )
	addNormal( 0, 1, 0 )
	addNormal( -1, 0, 0 )
	addNormal( 0, -1, 0 )
	addNormal( 0, 0, -1 )
	addNormal( 0, 0, 1 )

	local uvs = {}
	local addUVs = function( u, v )
		table.insert( uvs, {u,v} )
	end

	addUVs(0,0)
	addUVs(0,1)
	addUVs(1,1)
	addUVs(1,0)

	local color = {1,1,1}

	local setVertex = function( p, uv, n )
		vbo:writeFloat ( unpack(vertexes[p+1]) ) 
		-- vbo:writeFloat( unpack(normals[n]) )
		vbo:writeFloat( unpack(uvs[uv]) )
		vbo:writeColor32 ( unpack(color) )
	end

	local setTriangle = function( p1, p2, p3, uv1, uv2, uv3, n )
		setVertex( p1, uv1, n )
		setVertex( p2, uv2, n )
		setVertex( p3, uv3, n )
	end

	local setPoly = function( p1, p2, p3, p4, uv1, uv2, uv3, uv4, n )
		setTriangle( p1, p2, p3, uv1, uv2, uv3, n )
		setTriangle( p3, p4, p1, uv3, uv4, uv1, n )
	end

	setPoly( 0, 2, 3, 1, 1, 2, 3, 4, 1 ) 
	setPoly( 4, 6, 7, 5, 1, 2, 3, 4, 1 )
	setPoly( 4, 5, 0, 1, 1, 2, 3, 4, 1 )
	setPoly( 7, 6, 3, 2, 1, 2, 3, 4, 1 )
	setPoly( 5, 7, 2, 0, 1, 2, 3, 4, 1 )
	setPoly( 1, 3, 6, 4, 1, 2, 3, 4, 1 )
	-- MESH
	local mesh = MOAIMesh.new ()
	mesh:setVertexBuffer( vbo, vertexFormat )
	mesh:setTexture ( self.multi )
	mesh:setPrimType ( MOAIMesh.GL_TRIANGLES )
	mesh:setShader ( self.shader )--MOAIShaderMgr.getShader( MOAIShaderMgr.MESH_SHADER ) )
	-- mesh:setShader ( MOAIShaderMgr.getShader ( MOAIShaderMgr.LINE_SHADER_3D ))
	mesh:setTotalElements( vbo:countElements( vertexFormat ) )
	mesh:setBounds( vbo:computeBounds( vertexFormat ) )
	return mesh
end

return M_