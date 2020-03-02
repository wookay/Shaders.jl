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

function microseconds(μs)
    μs
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

dtype_to_gl_type(::Type{Int8}) = GL_BYTE
dtype_to_gl_type(::Type{UInt8}) = GL_UNSIGNED_BYTE
dtype_to_gl_type(::Type{Int16}) = GL_SHORT
dtype_to_gl_type(::Type{UInt16}) = GL_UNSIGNED_SHORT
dtype_to_gl_type(::Type{Int32}) = GL_INT
dtype_to_gl_type(::Type{UInt32}) = GL_UNSIGNED_INT
dtype_to_gl_type(::Type{Float16}) = GL_HALF_FLOAT
dtype_to_gl_type(::Type{Float32}) = GL_FLOAT
