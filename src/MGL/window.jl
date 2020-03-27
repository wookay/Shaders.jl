# module Shaders.MGL

abstract type WindowConfig end

using ..ReviseShaders
using ModernGL
using CSyntax

GLSL(src) = string("#version 330 core\n", src)

function Base.run(::Type{T}) where {T <: WindowConfig}
    if isdefined(Main, :Revise)
        frame = stacktrace()[2]
        file = String(frame.file)
        dirfull = dirname(file)
        !haskey(ReviseShaders.Revise.watched_files, dirfull) && ReviseShaders.track(T, file)
    end
    runloop(T)
end

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

struct VertexArray
    id::GLuint
    prog::Program
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

function create_vertex_array(ctx, prog::Program, vao_id::GLuint, vbo::Buffer, name::String)::VertexArray
    (vao_count, number_of_components) = vbo.size
    al = glGetAttribLocation(prog.id, name)
    (CHK ∘ glVertexAttribPointer)(al, number_of_components, GL_FLOAT, GL_FALSE, vao_count * sizeof(Cfloat), C_NULL)
    (CHK ∘ glEnableVertexAttribArray)(al)
    VertexArray(vao_id, prog, vao_count)
end

function create_vertex_array(ctx, prog::Program, vertices::Matrix, name::String)::VertexArray
    vao_id = GLuint(0)
    @c (CHK ∘ glGenVertexArrays)(1, &vao_id)

    vbo = (create ∘ Buffer)(ctx, vertices)

    (CHK ∘ glBindVertexArray)(vao_id)
    create_vertex_array(ctx, prog, vao_id, vbo, name)
end
Base.:∘(::typeof(create), ::Type{VertexArray}) = create_vertex_array

function render(vao::VertexArray, mode)
    (CHK ∘ glUseProgram)(vao.prog.id)
    (CHK ∘ glBindVertexArray)(vao.id)
    (CHK ∘ glDrawArrays)(mode, 0, vao.count)
end

# module Shaders.MGL
