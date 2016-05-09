
local vsh = [=[
uniform mat4 transform;

attribute vec4 position;
attribute vec2 uv;
attribute vec4 color;

varying vec4 colorVarying;
varying vec2 uvVarying;

void main () {
    gl_Position = position;
	uvVarying = uv;
    colorVarying = color;
}
]=]

local fsh = [=[
uniform float viewWidth;
uniform float viewHeight;

varying LOWP vec4 colorVarying;
varying MEDP vec2 uvVarying;

uniform sampler2D sampler;

const vec2 DIR = vec2(1.0, 1.0);

const float RADIUS = 1.0;

void main() {
	vec4 sum = vec4(0.0);

	vec2 tc = uvVarying;

	float blur = RADIUS / viewWidth;

	float hstep = DIR.x;
	float vstep = DIR.y;

    sum += texture2D(sampler, vec2(tc.x - 4.0*blur*hstep, tc.y - 4.0*blur*vstep)) * 0.0162162162;
    sum += texture2D(sampler, vec2(tc.x - 3.0*blur*hstep, tc.y - 3.0*blur*vstep)) * 0.0540540541;
    sum += texture2D(sampler, vec2(tc.x - 2.0*blur*hstep, tc.y - 2.0*blur*vstep)) * 0.1216216216;
    sum += texture2D(sampler, vec2(tc.x - 1.0*blur*hstep, tc.y - 1.0*blur*vstep)) * 0.1945945946;

    sum += texture2D(sampler, vec2(tc.x, tc.y)) * 0.2270270270;

    sum += texture2D(sampler, vec2(tc.x + 1.0*blur*hstep, tc.y + 1.0*blur*vstep)) * 0.1945945946;
    sum += texture2D(sampler, vec2(tc.x + 2.0*blur*hstep, tc.y + 2.0*blur*vstep)) * 0.1216216216;
    sum += texture2D(sampler, vec2(tc.x + 3.0*blur*hstep, tc.y + 3.0*blur*vstep)) * 0.0540540541;
    sum += texture2D(sampler, vec2(tc.x + 4.0*blur*hstep, tc.y + 4.0*blur*vstep)) * 0.0162162162;

    gl_FragColor = colorVarying * vec4(sum.rgb, 1.0);
}
]=]

local sizeW, sizeH, sizeD = 6, 1, 10

local M_ = {}

function M_:setup( layer )
	self:createShaderProgram()
	self:createShader()
	self:createFrameBuffer()

	local prop2 = self:addMyMesh()
	prop2:setLoc( 0, 0, 0 )
	self.layer:insertProp ( prop2 )

	local prop = self:loadMesh()
	prop:setLoc( 0, 0, -200 )
	self.layer:insertProp ( prop )

	local bprop = self:createBufferProp()
	bprop:setShader( self.shader ) -- self.shader
	layer:insertProp ( bprop )
end

function M_:createShaderProgram()
	local program = MOAIShaderProgram.new ()

	program:setVertexAttribute ( 1, 'position' )
	program:setVertexAttribute ( 2, 'uv' )
	program:setVertexAttribute ( 3, 'color' )

	program:reserveUniforms ( 3 )
	program:declareUniform ( 1, 'transform', MOAIShaderProgram.UNIFORM_MATRIX_F4 )
	program:declareUniform ( 2, 'viewWidth', MOAIShaderProgram.UNIFORM_FLOAT )
	program:declareUniform ( 3, 'viewHeight', MOAIShaderProgram.UNIFORM_FLOAT )

	program:reserveGlobals ( 3 )
	program:setGlobal ( 1, 1, MOAIShaderProgram.GLOBAL_WORLD_VIEW_PROJ )
	program:setGlobal ( 2, 2, MOAIShaderProgram.GLOBAL_VIEW_WIDTH )
	program:setGlobal ( 3, 3, MOAIShaderProgram.GLOBAL_VIEW_HEIGHT )

	program:load ( vsh, fsh )

	self.program = program
end

function M_:createShader()
	local shader = MOAIShader.new ()
	shader:setProgram ( self.program )
	self.shader = shader
end

function M_:createFrameBuffer()
	local viewport = MOAIViewport.new ()
	viewport:setSize(App.screenWidth, App.screenHeight)
    viewport:setScale(App.viewWidth, App.viewHeight)

	local layer = MOAILayer.new ()
	layer:setViewport ( viewport )

	local camera = MOAICamera.new ()
	camera:setLoc( 0, 500, 1000 )
	camera:lookAt( 0, 0, 500 )
	camera:setOrtho( false )

	layer:setCamera ( camera )
	
	local frameBuffer = MOAIFrameBufferTexture.new ()
	frameBuffer:setRenderTable ({ layer })
	frameBuffer:init ( App.viewWidth, App.viewHeight )
	frameBuffer:setClearColor ( 0, 0, 0, 1 )

	MOAIRenderMgr.setBufferTable ({ frameBuffer })
	
	self.frameBuffer = frameBuffer
	self.layer = layer
end

function M_:createBufferProp()
	local gfxQuad = MOAIGfxQuad2D.new ()
	-- gfxQuad:setTexture ( self.frameBuffer )
	gfxQuad:setRect ( -App.viewWidth*0.5, -App.viewHeight*0.5, App.viewWidth*0.5, App.viewHeight*0.5 )
	gfxQuad:setUVRect ( 0, 0, 1, 1 )

	local prop = MOAIProp2D.new ()
	prop:setTexture ( self.frameBuffer )
	prop:setDeck ( gfxQuad )
	return prop
end

function M_:loadMesh()
	local file = MOAIFileSystem.loadFile( 'assets/3ds/MyBoxy.mesh' )
    local mesh = assert( loadstring(file) )()

    print('mesh', mesh, mesh.textureName)

    mesh:setTexture ( "assets/3ds/moai.png" )
    mesh:setShader ( MOAIShaderMgr.getShader( MOAIShaderMgr.MESH_SHADER ) )

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
	mesh:setTexture ( "assets/3ds/moai.png" )
	mesh:setPrimType ( MOAIMesh.GL_TRIANGLES )
	mesh:setShader ( MOAIShaderMgr.getShader( MOAIShaderMgr.MESH_SHADER ) )
	-- mesh:setShader ( MOAIShaderMgr.getShader ( MOAIShaderMgr.LINE_SHADER_3D ))
	mesh:setTotalElements( vbo:countElements( vertexFormat ) )
	mesh:setBounds( vbo:computeBounds( vertexFormat ) )
	return mesh
end

return M_