@enum DepthTest Never Less Equal LessEqual Greater NotEqual GreaterEqual Always
@enum BlendMode None AlphaBlend

mutable struct RenderPass
    m_targets::Vector
    m_clear::Bool
    m_clear_color::Vector{RGBA}
    m_clear_depth::Cfloat
    m_clear_stencil::UInt8
    m_viewport_offset::Vector2i
    m_viewport_size::Vector2i
    m_framebuffer_size::Vector2i
    m_depth_test::DepthTest
    m_depth_write::Bool
#    CullMode m_cull_mode;
#   ref<Object> m_blit_target;
    m_active::Bool
    m_framebuffer_handle::UInt64
    m_viewport_backup::SVector{4, Cint}
    m_scissor_backup::SVector{4, Cint}
    m_depth_test_backup::Bool
    m_depth_write_backup::Bool
    m_scissor_test_backup::Bool
    m_cull_face_backup::Bool
    m_blend_backup::Bool
end

struct Texture
    flags
    size::Vector2i
end

@enum BufferType Unknown VertexBuffer VertexTexture VertexSampler FragmentBuffer FragmentTexture FragmentSampler UniformBuffer IndexBuffer
@enum PrimitiveType Point Line LineStrip Triangle TriangleStrip

mutable struct ShaderBuffer
    buffer::Ptr{Cvoid}
    buffer_type::BufferType
    dtype::Union{Type{Array},DataType}
    index::Cint
    ndim::Csize_t
    shape::Vector{Int}
    size::Csize_t
    dirty::Bool
end

struct Shader
    render_pass::RenderPass
    name::String
    m_buffers::Dict{String, ShaderBuffer}
    m_blend_mode::BlendMode 
    m_shader_handle::UInt32
    m_vertex_array_handle::UInt32
    m_uses_point_size::Bool
end

abstract type AbstractShader end

struct VertexShader <: AbstractShader
    body::String
end

struct FragmentShader <: AbstractShader
    body::String
end

function RenderPass(color_targets::Vector, depth_target, stencil_target, blit_target, clear::Bool)
    m_targets = Vector(undef, length(color_targets) + 2)
    m_clear = clear
    m_clear_color = Vector{RGBA}(undef, length(color_targets))
    m_viewport_offset::Vector2i = (0, 0)
    m_viewport_size::Vector2i = (0, 0)
    m_framebuffer_size::Vector2i = (0, 0)
    m_depth_test = Less
    m_depth_write = true
    #m_cull_mode(CullMode::Back)
    #m_blit_target(blit_target)
    m_active = false

    m_targets[1] = depth_target
    m_targets[2] = stencil_target
    for i in 1:length(color_targets)
         m_targets[i + 2] = color_targets[i]
         m_clear_color[i] = RGBA(0, 0, 0, 0)
    end
    m_clear_stencil::UInt8 = 0
    m_clear_depth::Cfloat = 1.0
    if C_NULL == m_targets[1]
        m_depth_write = false
        m_depth_test = Always
    end

    m_framebuffer_handle_32 = UInt32(0)
    @c (CHK ∘ glGenFramebuffers)(1, &m_framebuffer_handle_32)
    m_framebuffer_handle = UInt64(m_framebuffer_handle_32)
    (CHK ∘ glBindFramebuffer)(GL_FRAMEBUFFER, m_framebuffer_handle)

    draw_buffers = Vector{GLenum}()

    has_texture = false
    has_screen  = false

    for (i, target) in enumerate(m_targets)
        if i == 1
            attachment_id = GL_DEPTH_ATTACHMENT
        elseif i == 2
            attachment_id = GL_STENCIL_ATTACHMENT
        else
            attachment_id = GLenum(GL_COLOR_ATTACHMENT0 + i - 2)
        end

        if target isa Screen
            m_framebuffer_size = max(m_framebuffer_size, target.fbsize)
            i >= 2 && push!(draw_buffers, GL_BACK_LEFT)
            has_screen = true
        elseif target isa Texture
            #if (texture->flags() & Texture::TextureFlags::ShaderRead) {
            #    CHK(glFramebufferTexture2D(GL_FRAMEBUFFER, attachment_id, GL_TEXTURE_2D,
            #                               texture->texture_handle(), 0));
            #} else {
            #    CHK(glFramebufferRenderbuffer(GL_FRAMEBUFFER, attachment_id, GL_RENDERBUFFER,
            #                                  texture->renderbuffer_handle()));
            i >= 2 && push!(draw_buffers, attachment_id)
            m_framebuffer_size = max(m_framebuffer_size, target.size)
            has_texture = true
        end
    end
    m_viewport_size = m_framebuffer_size
    if has_screen && !has_texture
        m_framebuffer_handle_32 = UInt32(m_framebuffer_handle)
        @c (CHK ∘ glDeleteFramebuffers)(1, &m_framebuffer_handle_32)
        m_framebuffer_handle = UInt64(0)
    else
        (CHK ∘ glDrawBuffers)(GLsizei(length(draw_buffers)), draw_buffers)
        status = glCheckFramebufferStatus(GL_FRAMEBUFFER)
        if status != GL_FRAMEBUFFER_COMPLETE
            throw(RuntimeError(string("RenderPass() framebuffer is marked as incomplete: ", status)))
        end
    end
    (CHK ∘ glBindFramebuffer)(GL_FRAMEBUFFER, 0)

    m_viewport_backup = SVector{4, Cint}(0, 0, 0, 0)
    m_scissor_backup = SVector{4, Cint}(0, 0, 0, 0)
    m_depth_test_backup = false
    m_depth_write_backup = false
    m_scissor_test_backup = false
    m_cull_face_backup = false
    m_blend_backup = false
    RenderPass(
        m_targets::Vector,
        m_clear::Bool,
        m_clear_color::Vector{RGBA},
        m_clear_depth::Cfloat,
        m_clear_stencil::UInt8,
        m_viewport_offset::Vector2i,
        m_viewport_size::Vector2i,
        m_framebuffer_size::Vector2i,
        m_depth_test::DepthTest,
        m_depth_write::Bool,
#        CullMode m_cull_mode;
#       ref<Object> m_blit_target;
        m_active::Bool,
        m_framebuffer_handle::UInt64,
        m_viewport_backup::SVector{4, Cint},
        m_scissor_backup::SVector{4, Cint},
        m_depth_test_backup::Bool,
        m_depth_write_backup::Bool,
        m_scissor_test_backup::Bool,
        m_cull_face_backup::Bool,
        m_blend_backup::Bool)
end

function begin_render_pass(render_pass::RenderPass)
    render_pass.m_active = true
    (CHK ∘ glGetIntegerv)(GL_VIEWPORT, render_pass.m_viewport_backup)
    (CHK ∘ glGetIntegerv)(GL_SCISSOR_BOX, render_pass.m_scissor_backup)

    depth_write = GLboolean(false)
    @c (CHK ∘ glGetBooleanv)(GL_DEPTH_WRITEMASK, &depth_write)
    m_depth_write_backup = depth_write

    m_depth_test_backup = glIsEnabled(GL_DEPTH_TEST)
    m_scissor_test_backup = glIsEnabled(GL_SCISSOR_TEST)
    m_cull_face_backup = glIsEnabled(GL_CULL_FACE)
    m_blend_backup = glIsEnabled(GL_BLEND)

    (CHK ∘ glBindFramebuffer)(GL_FRAMEBUFFER, render_pass.m_framebuffer_handle)
    set_viewport(render_pass, render_pass.m_viewport_offset, render_pass.m_viewport_size)
end

function set_viewport(render_pass::RenderPass, offset::Vector2i, size::Vector2i)
    render_pass.m_viewport_offset = offset
    render_pass.m_viewport_size = size

    if render_pass.m_active
        ypos = render_pass.m_framebuffer_size[2] - render_pass.m_viewport_size[2] - render_pass.m_viewport_offset[2]
        (CHK ∘ glViewport)(render_pass.m_viewport_offset[1], ypos, render_pass.m_viewport_size...)
        (CHK ∘ glScissor)(render_pass.m_viewport_offset[1], ypos, render_pass.m_viewport_size...)
        if render_pass.m_viewport_offset == Vector2i(0, 0) && render_pass.m_viewport_size == render_pass.m_framebuffer_size
            (CHK ∘ glDisable)(GL_SCISSOR_TEST)
        else
            (CHK ∘ glEnable)(GL_SCISSOR_TEST)
        end
    end
end

function end_render_pass(render_pass::RenderPass)
end

function set_uniform(shader::Shader, name::String, value::Array)
    shape = [1, 1, 1]
    if ndims(value) == 0
        data = Ref(value)
        ndim = 0
    elseif ndims(value) == 1
        data = value
        shape[1] = length(value)
        ndim = 1
    elseif ndims(value) == 2
        data = value
        shape[1] = length(value)
        shape[2] = length(value[1])
        ndim = 2
    elseif ndims(value) == 3
        data = value
        shape[1] = length(value)
        shape[2] = length(value[1])
        shape[3] = length(value[1][1])
        ndim = 3
    else
        throw(RuntimeError("Shader::set_uniform(): invalid input array dimension!"))
    end
    set_buffer(shader.m_buffers, name, Array, ndim, shape, data)
end

function begin_shader(shader::Shader)
    texture_unit = 0

    (CHK ∘ glUseProgram)(shader.m_shader_handle)

    (CHK ∘ glBindVertexArray)(shader.m_vertex_array_handle)

    for (key, buf) in pairs(shader.m_buffers)
        @info :key key
        indices = key == "indices"
        if buf.buffer == C_NULL
            if !indices
            end
            continue
        end
        buffer_id = UInt64(buf.buffer)
        gl_type = GLenum(0)

        if !buf.dirty && buf.buffer_type != VertexTexture && buf.buffer_type != FragmentTexture
            continue
        end

        uniform_error = false
        if buf.buffer_type == IndexBuffer
            (CHK ∘ glBindBuffer)(GL_ELEMENT_ARRAY_BUFFER, buffer_id)
        elseif buf.buffer_type == VertexBuffer
            (CHK ∘ glBindBuffer)(GL_ARRAY_BUFFER, buffer_id)
            (CHK ∘ glEnableVertexAttribArray)(buf.index)

            gl_type = dtype_to_gl_type(buf.dtype)

            if buf.ndim != 2
                msg = string(shader.name, ": vertex attribute ", key, " has an invalid shapeension (expected ndim=2, got ", buf.ndim)
                throw(RuntimeError(msg))
            end
            (CHK ∘ glVertexAttribPointer)(buf.index, GLint(buf.shape[2]), gl_type, false, 0, C_NULL)
        else
        end
    end
end

function end_shader(shader::Shader)
    if shader.m_blend_mode == AlphaBlend
        (CHK ∘ glDisable)(GL_BLEND)
    end
    if shader.m_uses_point_size
        (CHK ∘ glDisable)(GL_PROGRAM_POINT_SIZE)
    end
    (CHK ∘ glBindVertexArray)(0)
    (CHK ∘ glUseProgram)(0)
end

function compile_gl_shader(shader_type::GLenum, name::String, shader::AbstractShader)::UInt64
    isempty(shader.body) && UInt64(0)

    id = glCreateShader(shader_type)
    shader_string_ptr = Ptr{GLchar}[pointer(shader.body)]
    (CHK ∘ glShaderSource)(id, 1, shader_string_ptr, C_NULL)
    (CHK ∘ glCompileShader)(id)

    status = GLint(0)
    @c (CHK ∘ glGetShaderiv)(id, GL_COMPILE_STATUS, &status)

    if status != true
        shader_type_name = if GL_VERTEX_SHADER == shader_type
            :VERTEX_SHADER
        elseif GL_FRAGMENT_SHADER == shader_type
            :FRAGMENT_SHADER 
        elseif GL_GEOMETRY_SHADER == shader_type
            :GEOMETRY_SHADER
        else
            :UNKNOWN_SHADER
        end

        max_length = GLsizei(0)
        @c (CHK ∘ glGetShaderiv)(id, GL_INFO_LOG_LENGTH, &max_length)
        actual_length = GLsizei(0)
        log = Vector{GLchar}(undef, max_length)
        @c (CHK ∘ glGetShaderInfoLog)(id, max_length, &actual_length, log)
        error_shader = String(log)
        msg = string("compile_gl_shader(): unable to compile ", shader_type_name, " ", name, " ", error_shader)
        throw(RuntimeError(msg))
    end
    return id
end

function Shader(render_pass::RenderPass, name::String, vertex_shader::VertexShader, fragment_shader::FragmentShader, blend_mode::BlendMode)
    vertex_shader_handle  = compile_gl_shader(GL_VERTEX_SHADER, name, vertex_shader)
    fragment_shader_handle = compile_gl_shader(GL_FRAGMENT_SHADER, name, fragment_shader)

    m_shader_handle = glCreateProgram()

    (CHK ∘ glAttachShader)(m_shader_handle, vertex_shader_handle)
    (CHK ∘ glAttachShader)(m_shader_handle, fragment_shader_handle)
    (CHK ∘ glLinkProgram)(m_shader_handle)
    (CHK ∘ glDeleteShader)(vertex_shader_handle)
    (CHK ∘ glDeleteShader)(fragment_shader_handle)

    status::GLint = 0
    @c (CHK ∘ glGetProgramiv)(m_shader_handle, GL_LINK_STATUS, &status)

    if status != true
        msg = string("Shader " + name + ": unable to link shader!")
        throw(RuntimeError(msg))
    end

    attribute_count = GLint(0)
    @c (CHK ∘ glGetProgramiv)(m_shader_handle, GL_ACTIVE_ATTRIBUTES, &attribute_count)
    uniform_count = GLint(0)
    @c (CHK ∘ glGetProgramiv)(m_shader_handle, GL_ACTIVE_UNIFORMS, &uniform_count)

    m_buffers = Dict{String, ShaderBuffer}()
    for i in 1:attribute_count
        shader_name = Vector{UInt8}(undef, 128)
        shader_size = GLint(0)
        gl_type = GLenum(0)
        @c (CHK ∘ glGetActiveAttrib)(m_shader_handle, i - 1, sizeof(shader_name), C_NULL, &shader_size, &gl_type, shader_name)
        index = glGetAttribLocation(m_shader_handle, shader_name)
        register_buffer(m_buffers, VertexBuffer, unsafe_string(pointer(shader_name)), index, gl_type)
    end

    for i in 1:uniform_count
        shader_name = Vector{UInt8}(undef, 128)
        shader_size = GLint(0)
        gl_type = GLenum(0)
        @c (CHK ∘ glGetActiveUniform)(m_shader_handle, i - 1, sizeof(shader_name), C_NULL, &shader_size, &gl_type, shader_name)
        index = glGetUniformLocation(m_shader_handle, shader_name)
        register_buffer(m_buffers, UniformBuffer, unsafe_string(pointer(shader_name)), index, gl_type)
    end

    dtype = UInt32
    shape = [0, 1, 1]
    size = sizeof(dtype) * reduce(*, shape)
    dirty = false
    buf = ShaderBuffer(C_NULL, IndexBuffer, dtype, -1, Csize_t(1), shape, size, dirty)
    m_buffers["indices"] = buf

    m_vertex_array_handle = UInt32(0)
    @c (CHK ∘ glGenVertexArrays)(1, &m_vertex_array_handle)

    m_uses_point_size = false
    # m_uses_point_size = vertex_shader.find("gl_PointSize") != std::string::npos;

    Shader(
        render_pass::RenderPass,
        name::String,
        m_buffers::Dict{String, ShaderBuffer},
        blend_mode::BlendMode,
        m_shader_handle::UInt32,
        m_vertex_array_handle::UInt32,
        m_uses_point_size::Bool
    )
end

function register_buffer(m_buffers::Dict{String, ShaderBuffer}, buffer_type::BufferType, shader_name::String, index::Cint, gl_type::GLenum)
    shape = Vector{Int}([1, 1, 1])
    ndim = 1 
    dtype = Nothing
    if gl_type == GL_FLOAT
        dtype = Float32
        ndim = 0
    elseif gl_type == GL_FLOAT_VEC2
        dtype = Float32
        shape[1] = 2
    elseif gl_type == GL_FLOAT_VEC3
        dtype = Float32
        shape[1] = 3
    elseif gl_type == GL_FLOAT_VEC4
        dtype = Float32
        shape[1] = 4
    elseif gl_type == GL_INT
        dtype = Int32
        ndim = 0
    elseif gl_type == GL_INT_VEC2
        dtype = Int32
        shape[1] = 2
    elseif gl_type == GL_INT_VEC3
        dtype = Int32
        shape[1] = 3
    elseif gl_type == GL_INT_VEC4
        dtype = Int32
        shape[1] = 4
    elseif gl_type == GL_UNSIGNED_INT
        dtype = UInt32
        ndim = 0
    elseif gl_type == GL_UNSIGNED_INT_VEC2
        dtype = UInt32
        shape[1] = 2
    elseif gl_type == GL_UNSIGNED_INT_VEC3
        dtype = UInt32
        shape[1] = 3
    elseif gl_type == GL_UNSIGNED_INT_VEC4
        dtype = UInt32
        shape[1] = 4
    elseif gl_type == GL_BOOL
        dtype = Bool
        ndim = 0
    elseif gl_type == GL_BOOL_VEC2
        dtype = Bool
        shape[1] = 2
    elseif gl_type == GL_BOOL_VEC3
        dtype = Bool
        shape[1] = 3
    elseif gl_type == GL_BOOL_VEC4
        dtype = Bool
        shape[1] = 4
    elseif gl_type == GL_FLOAT_MAT2
        dtype = Float32
        shape[1] = shape[2] = 2
        ndim = 2
    elseif gl_type == GL_FLOAT_MAT3
        dtype = Float32
        shape[1] = shape[2] = 3
        ndim = 2
    elseif gl_type == GL_FLOAT_MAT4
        dtype = Float32
        shape[1] = shape[2] = 4
        ndim = 2
    elseif gl_type == GL_SAMPLER_2D
        dtype = Nothing
        ndim = 0
        buffer_type = FragmentTexture
    else
        throw(RuntimeError("Shader(): unsupported uniform/attribute type!"))
    end
    buffer = C_NULL
    size = sizeof(dtype) * reduce(*, shape)
    dirty = false
    buf = ShaderBuffer(buffer, buffer_type, dtype, index, Csize_t(ndim), shape, size, dirty)
    if buffer_type == VertexBuffer
        # for (int i = (int) buf.ndim - 1; i >= 0; --i) {
        #    buf.shape[i + 1] = buf.shape[i];
        # buf.shape[0] = 0;
        # buf.ndim++;
    end
    @info :shader_name shader_name
    m_buffers[shader_name] = buf
end

function set_buffer(m_buffers::Dict{String, ShaderBuffer}, shader_name::String, dtype::Union{Type{Array},DataType}, ndim::Int, shape::Vector{Int}, data)
    @info :data data[1:3]
    buf = m_buffers[shader_name]
    if dtype === Array
        size = sizeof(Float64) * reduce(*, shape)
    else
        size = sizeof(dtype) * reduce(*, shape)
    end

    if buf.buffer_type == UniformBuffer
        if buf.buffer != C_NULL && buf.size != size
            buf.buffer = C_NULL
            GC.gc()
        end
        if buf.buffer == C_NULL
            buf.buffer = pointer(Vector{UInt8}(undef, size))
        end
        unsafe_copyto!(buf.buffer, Ptr{Cvoid}(pointer(data)), Csize_t(size))
    else
        buffer_id::UInt64 = 0
        if buf.buffer != C_NULL
            buffer_id = UInt64(buf)
        else
            buffer_id_32 = UInt32(0)
            @c (CHK ∘ glGenBuffers)(1, &buffer_id_32)
            buffer_id = UInt64(buffer_id_32)
            buf.buffer = Ptr{Cvoid}(buffer_id)
        end
        buf_type = GLenum(shader_name == "indices" ? GL_ELEMENT_ARRAY_BUFFER : GL_ARRAY_BUFFER)
        (CHK ∘ glBindBuffer)(buf_type, buffer_id)
        (CHK ∘ glBufferData)(buf_type, size, data, GL_DYNAMIC_DRAW)
    end

    buf.dtype = dtype
    buf.ndim  = ndim
    buf.shape = shape
    buf.size  = size
    buf.dirty = true
end

function draw_array(primitive_type::PrimitiveType, offset::Int, count::Int, indexed::Bool)
    primitive_type_gl = if primitive_type == Point
        GL_POINTS
    elseif primitive_type == Line
        GL_LINES
    elseif primitive_type == LineStrip
        GL_LINE_STRIP
    elseif primitive_type == Triangle
        GL_TRIANGLES
    elseif primitive_type == TriangleStrip
        GL_TRIANGLE_STRIP
    else
        throw(RuntimeError("Shader::draw_array(): invalid primitive type!"))
    end
    if !indexed
        (CHK ∘ glDrawArrays)(primitive_type_gl, GLint(offset), GLsizei(count))
    else
        (CHK ∘ glDrawElements)(primitive_type_gl, GLsizei(count), GL_UNSIGNED_INT, Ptr{Cvoid}(offset * sizeof(UInt32)))
    end
end
