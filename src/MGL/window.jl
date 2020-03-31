# module Shaders.MGL

abstract type WindowConfig end

using ModernGL
using CSyntax

GLSL(src) = string("#version 330 core\n", src)

function render
end

function create
end

struct Program
    id
end

struct Buffer
    data
    size
end

struct IndexBuffer{T}
    indices
end

struct VertexArray
    prog::Program
    id::GLuint
    count
end

function CHK(::Nothing)
    err = glGetError()
    err == GL_NO_ERROR && return
    printstyled("CHK ", color=:red)
    println.(stacktrace())
    println(err == GL_INVALID_ENUM ? "GL_INVALID_ENUM: An unacceptable value is specified for an enumerated argument. The offending command is ignored and has no other side effect than to set the error flag." :
    err == GL_INVALID_VALUE ? "GL_INVALID_VALUE: A numeric argument is out of range. The offending command is ignored and has no other side effect than to set the error flag." :
    err == GL_INVALID_OPERATION ? "GL_INVALID_OPERATION: The specified operation is not allowed in the current state. The offending command is ignored and has no other side effect than to set the error flag." :
    err == GL_INVALID_FRAMEBUFFER_OPERATION ? "GL_INVALID_FRAMEBUFFER_OPERATION: The framebuffer object is not complete. The offending command is ignored and has no other side effect than to set the error flag." :
    err == GL_OUT_OF_MEMORY ? "GL_OUT_OF_MEMORY: There is not enough memory left to execute the command. The state of the GL is undefined, except for the state of the error flags, after this error is recorded." : "Unknown OpenGL error with error code $err.")
end

function before
end

function after
end

const _debug_env = get(ENV, "DEBUG", nothing) !== nothing
_debug_chk = _debug_env

function Base.:∘(::typeof(before), ::typeof(render))
    global _debug_chk = false
end

function Base.:∘(::typeof(after), ::typeof(render))
    global _debug_chk = _debug_env
end

function Base.:∘(::typeof(CHK), f::Function)
    global _debug_chk
    function (args...)
        if _debug_chk
            print("(CHK ∘ ")
            printstyled(f, color=:yellow)
            print(")", args, "\n")
        end
        CHK(f(args...))
    end
end

function CHK_glCompileShader(shader)
    CHK(glCompileShader(shader))
    success = GLint(0)
    @c (CHK ∘ glGetShaderiv)(shader, GL_COMPILE_STATUS, &success)
    if success == GL_FALSE
        maxLength = GLint(0)
        @c (CHK ∘ glGetShaderiv)(shader, GL_INFO_LOG_LENGTH, &maxLength)
        actualLength = GLsizei(0)
        infoLog = Vector{GLchar}(undef, maxLength)
        @c (CHK ∘ glGetShaderInfoLog)(shader, maxLength, &actualLength, infoLog)
        (CHK ∘ glDeleteShader)(shader)
        @info String(infoLog)
    end
end

Base.:∘(::typeof(CHK), ::typeof(glCompileShader)) = CHK_glCompileShader

function CHK_glLinkProgram(program)
    CHK(glLinkProgram(program))
    success = GLint(0)
    @c (CHK ∘ glGetProgramiv)(program, GL_LINK_STATUS, &success)
    if success == GL_FALSE
        maxLength = GLint(0)
        @c (CHK ∘ glGetProgramiv)(program, GL_INFO_LOG_LENGTH, &maxLength)
        actualLength = GLsizei(0)
        infoLog = Vector{GLchar}(undef, maxLength)
        @c (CHK ∘ glGetProgramInfoLog)(program, maxLength, &actualLength, infoLog)
        (CHK ∘ glDeleteProgram)(program)
        @info String(infoLog)
    end
end
Base.:∘(::typeof(CHK), ::typeof(glLinkProgram)) = CHK_glLinkProgram

function create_program(; vertex_shader::String, fragment_shader::String)::Program
    vs = glCreateShader(GL_VERTEX_SHADER)
    (CHK ∘ glShaderSource)(vs, 1, (Ref ∘ pointer)(vertex_shader), C_NULL)
    (CHK ∘ glCompileShader)(vs)

    fs = glCreateShader(GL_FRAGMENT_SHADER)
    (CHK ∘ glShaderSource)(fs, 1, (Ref ∘ pointer)(fragment_shader), C_NULL)
    (CHK ∘ glCompileShader)(fs)

    prog_id = glCreateProgram()
    (CHK ∘ glAttachShader)(prog_id, vs)
    (CHK ∘ glAttachShader)(prog_id, fs)
    (CHK ∘ glLinkProgram)(prog_id)

    Program(prog_id)
end
Base.:∘(::typeof(create), ::Type{Program}) = create_program

function create_buffer(ctx, data)::Buffer
    vbo_id = GLuint(0)
    @c (CHK ∘ glGenBuffers)(1, &vbo_id)

    (CHK ∘ glBindBuffer)(GL_ARRAY_BUFFER, vbo_id)
    vertices = Cfloat.(vec(data'))
    (CHK ∘ glBufferData)(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW)
    Buffer(vertices, size(data))
end
Base.:∘(::typeof(create), ::Type{Buffer}) = create_buffer

function create_vertex_array(ctx, prog::Program, content::NamedTuple, index_buffer::Union{Nothing,IndexBuffer}=nothing)::VertexArray
    vao_id = GLuint(0)
    @c (CHK ∘ glGenVertexArrays)(1, &vao_id)

    vao_count = 0
    for (sym, vertices) in pairs(content)
        vbo = (create ∘ Buffer)(ctx, vertices)
        name = String(sym)
        (CHK ∘ glBindVertexArray)(vao_id)
        (num_rows, num_components) = vbo.size
        vao_count += num_rows
        location = glGetAttribLocation(prog.id, name)
        (CHK ∘ glVertexAttribPointer)(location, num_components, GL_FLOAT, GL_FALSE, 0, C_NULL)
        (CHK ∘ glEnableVertexAttribArray)(location)
    end

    VertexArray(prog, vao_id, vao_count)
end

function create_vertex_array(ctx, prog::Program, vertices::AbstractArray{T,2}, name::String)::VertexArray where T
    content = NamedTuple{(Symbol(name),)}((vertices,))
    create_vertex_array(ctx, prog, content)
end
Base.:∘(::typeof(create), ::Type{VertexArray}) = create_vertex_array

function render(vao::VertexArray, mode::GLenum=ModernGL.GL_TRIANGLES; first=0)
    (CHK ∘ glUseProgram)(vao.prog.id)
    (CHK ∘ glBindVertexArray)(vao.id)

    (CHK ∘ glDrawArrays)(mode, first, vao.count)
end

# module Shaders.MGL
