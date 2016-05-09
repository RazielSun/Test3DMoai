----------------------------------------------------------------------------------------------------
-- @type MultitextureMask
--
-- MultitextureMask shader
----------------------------------------------------------------------------------------------------

local ShaderCache = require("core.ShaderCache")

local MultitextureMask = class()

--------------------------------------------------------------------------------

local prop_fsh = [=[
varying MEDP vec4 colorVarying;
varying MEDP vec2 uvVarying;
uniform sampler2D sampler1;
uniform sampler2D sampler2;
void main () {
    LOWP vec4 color = texture2D ( sampler1, uvVarying );
    LOWP vec4 maskColor = texture2D ( sampler2, uvVarying );
    gl_FragColor = color * colorVarying * maskColor[3];
}]=]

local prop_vsh = [=[
attribute vec4 position;
attribute vec2 uv;
attribute vec4 color;
varying MEDP vec4 colorVarying;
varying MEDP vec2 uvVarying;
void main () {
    gl_Position = position;
    uvVarying = uv;
    colorVarying = color;
}]=]

local function affirmPropProgram()
    local program = ShaderCache.getProgram("mutlitextureMaskProp")
    if not program then
        program = MOAIShaderProgram.new()
        program:setVertexAttribute ( 1, 'position' )
        program:setVertexAttribute ( 2, 'uv' )
    	program:setVertexAttribute ( 3, 'color' )
    	program:reserveUniforms ( 2 )
    	program:declareUniformSampler ( 1, 'sampler1', 1 )
    	program:declareUniformSampler ( 2, 'sampler2', 2 )

        program:load(prop_vsh, prop_fsh)

        ShaderCache.setProgram("mutlitextureMaskProp", program)
    end
    return program
end

--------------------------------------------------------------------------------
function MultitextureMask:init()
    local propShader = MOAIShader.new()
    propShader:setProgram( affirmPropProgram() )

    self.propShader = propShader
end

return MultitextureMask

--------------------------------------------------------------------------------
-- GfxQuadURLMutlitexture
-- 
-- 
--------------------------------------------------------------------------------

---
--  Used with only single texture, without atlas !!!
--

local GfxQuadURL = require("util.GfxQuadURL")

local GfxQuadURLMutlitexture = class(GfxQuadURL)

function GfxQuadURLMutlitexture:init(...)
    GfxQuadURL.init(self, ...)
end

function GfxQuadURLMutlitexture:affirmMultitexture()
    local multitexture = self.multitexture
    if not multitexture then
        multitexture = MOAIMultiTexture.new()
        multitexture:reserve(2)
        GfxQuadURL.setTexture(self, multitexture)
        self.multitexture = multitexture
    end
    return multitexture
end

function GfxQuadURLMutlitexture:setTexture(texture)
    local multi = self:affirmMultitexture()
    multi:setTexture(1, texture)
end

function GfxQuadURLMutlitexture:setMask(texture)
    local multi = self:affirmMultitexture()
    multi:setTexture(2, texture)
end

return GfxQuadURLMutlitexture
