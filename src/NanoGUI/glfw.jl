const Vector2i = SVector{2, Cint}
const Vector3f = SVector{3, Cfloat}

struct RuntimeError <: Exception
    msg::String
end

const GL_RGBA_FLOAT_MODE = 0x8820

function glfwGetTime()::Cdouble
    ccall((:glfwGetTime, GLFW.libglfw), Cdouble, ())
end

function glfwSetTime(time::Integer)
    ccall((:glfwSetTime, GLFW.libglfw), Cvoid, (Cdouble,), time)
end

function ModernGL.glClearColor(background::RGBA)
    glClearColor(background.r, background.g, background.b, background.alpha)
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT)
end

function CHK(::Nothing)
    err = glGetError()
    err == GL_NO_ERROR && return
    println.(stacktrace())
    println(err == GL_INVALID_ENUM ? "GL_INVALID_ENUM: An unacceptable value is specified for an enumerated argument. The offending command is ignored and has no other side effect than to set the error flag." :
    err == GL_INVALID_VALUE ? "GL_INVALID_VALUE: A numeric argument is out of range. The offending command is ignored and has no other side effect than to set the error flag." :
    err == GL_INVALID_OPERATION ? "GL_INVALID_OPERATION: The specified operation is not allowed in the current state. The offending command is ignored and has no other side effect than to set the error flag." :
    err == GL_INVALID_FRAMEBUFFER_OPERATION ? "GL_INVALID_FRAMEBUFFER_OPERATION: The framebuffer object is not complete. The offending command is ignored and has no other side effect than to set the error flag." :
    err == GL_OUT_OF_MEMORY ? "GL_OUT_OF_MEMORY: There is not enough memory left to execute the command. The state of the GL is undefined, except for the state of the error flags, after this error is recorded." : "Unknown OpenGL error with error code $err.")
end

function Base.:∘(chk::typeof(CHK), f::typeof(glCompileShader))
    function (shader)
        chk(f(shader))

        success = GLint(0)
        @c (CHK ∘ glGetShaderiv)(shader, GL_COMPILE_STATUS, &success)
        if success == GL_FALSE
            maxLength = GLint(0)
            @c (CHK ∘ glGetShaderiv)(shader, GL_INFO_LOG_LENGTH, &maxLength)
            actualLength = GLsizei(0)
            infoLog = Vector{GLchar}(undef, maxLength)
            @c (CHK ∘ glGetShaderInfoLog)(shader, maxLength, &actualLength, infoLog)
            @info String(infoLog)
        end
    end
end

function Base.:∘(chk::typeof(CHK), f::typeof(glLinkProgram))
    function (program)
        chk(f(program))

        success = GLint(0)
        @c (CHK ∘ glGetProgramiv)(program, GL_LINK_STATUS, &success)
        if success == GL_FALSE
            maxLength = GLint(0)
            @c (CHK ∘ glGetProgramiv)(program, GL_INFO_LOG_LENGTH, &maxLength)
            actualLength = GLsizei(0)
            infoLog = Vector{GLchar}(undef, maxLength)
            @c (CHK ∘ glGetProgramInfoLog)(program, maxLength, &actualLength, infoLog)
            @info String(infoLog)
        end
    end
end
