# module Shaders.MGL

using GLFW
using Colors
using StaticArrays

_glfw_initialized = false
_ctx_store = Dict{Type, Any}()

const Vector2i = SVector{2, Cint}
const Vector3f = SVector{3, Cfloat}
const Matrix4f = MMatrix{4, 4, Cfloat}

function glfwGetTime()::Cdouble
    ccall((:glfwGetTime, GLFW.libglfw), Cdouble, ())
end

function glfwSetTime(time::Integer)
    ccall((:glfwSetTime, GLFW.libglfw), Cvoid, (Cdouble,), time)
end

function glfw_init()
    # glfwSetErrorCallback
    if !GLFW.Init()
        throw(RuntimeError("Could not initialize GLFW!"))
    end
    glfwSetTime(0)
    _initialized = true
end

mutable struct Ctx
    app::Union{Nothing,Ref{<:WindowConfig}}
    task::Union{Nothing,Task}
    glfw_wnd
    background
end

function microseconds(μs)
    μs
end

function get_quantum(refresh::Float64)::Float32
    quantum_ms::Float32 = 0.0f0
    quantum_count::Csize_t = 1
    if refresh >= 0
        quantum_ms = microseconds(refresh * 1000)
        while quantum_ms > 50_000
            quantum_ms /= 2
            quantum_count *= 2
        end
    else
        quantum_ms = microseconds(50_000) # 50ms
        quantum_count = typemax(Csize_t)
    end
    quantum_ms * 1e-6
end

function set_visible(ctx, visible::Bool)
    (visible ? GLFW.ShowWindow : GLFW.HideWindow)(ctx.glfw_wnd)
end

function draw_all(app, glfw_wnd)
    glfw_time = glfwGetTime()

    GLFW.MakeContextCurrent(glfw_wnd)
    glClearColor(app.ctx.background)

    (before ∘ render)
    Base.invokelatest(render, app, glfw_time, 0)
    (after ∘ render)

    GLFW.SwapBuffers(glfw_wnd)
end

function mainloop(ctx::Ctx, refresh::Float64=1000inv(60), closenotify=Condition()) where {T <: WindowConfig}
    mainloop_active = true
    is_running = true

    key_callback = function (_, key, scancode, action, mods)
       if key == GLFW.KEY_ESCAPE && action == GLFW.PRESS
           is_running = false
           set_visible(ctx, false)
           return true
       end
    end
    GLFW.SetKeyCallback(ctx.glfw_wnd, key_callback)

    function mainloop_iteration(app) # mainloop_active
        if GLFW.WindowShouldClose(ctx.glfw_wnd)
            is_running = false
            set_visible(ctx, false)
        else
            draw_all(app, ctx.glfw_wnd)
        end
        if !is_running
            mainloop_active = false
            GLFW.DestroyWindow(ctx.glfw_wnd)
            ctx.glfw_wnd.handle = C_NULL
            GLFW.Terminate()
            notify(closenotify)
        end
    end

    function mainloop_func(app, quantum) # mainloop_active
        set_visible(ctx, true)
        while mainloop_active
            mainloop_iteration(app)
            yield()
            GLFW.WaitEvents(quantum)
        end
    end

    quantum = get_quantum(refresh)
    # mainloop_func(ctx.app[], quantum)
    ctx.task = Task(() -> mainloop_func(ctx.app[], quantum))

    schedule(ctx.task)

    iszero(Base.JLOptions().isinteractive) && wait(closenotify)
end

function get_pixel_ratio(glfw_wnd::GLFW.Window)::Cfloat
    fbsize = GLFW.GetFramebufferSize(glfw_wnd)
    wsize = GLFW.GetWindowSize(glfw_wnd)
    return fbsize[1] / wsize[1]
end

function glClearColor(background::RGBA)
    ModernGL.glClearColor(background.r, background.g, background.b, background.alpha)
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT)
end

function create_glfw_window(wsize::Vector2i = Vector2i((640, 480)); background::RGBA = RGBA(0.3, 0.3, 0.32, 1.), caption::String = "Unnamed", resizable::Bool = true, fullscreen::Bool = false, depth_buffer::Bool = true, stencil_buffer::Bool = true, float_buffer::Bool = false, gl_major::UInt = UInt(3), gl_minor::UInt = UInt(3))
    GLFW.WindowHint(GLFW.CLIENT_API,            GLFW.OPENGL_API)
    GLFW.WindowHint(GLFW.CONTEXT_VERSION_MAJOR, gl_major)
    GLFW.WindowHint(GLFW.CONTEXT_VERSION_MINOR, gl_minor)
    GLFW.WindowHint(GLFW.OPENGL_PROFILE,        GLFW.OPENGL_CORE_PROFILE)
    GLFW.WindowHint(GLFW.OPENGL_FORWARD_COMPAT, true)

    color_bits, depth_bits, stencil_bits = 8, 0, 0
    if stencil_buffer && !depth_buffer
        throw(RuntimeError("Screen stencil_buffer = true requires depth_buffer = true"))
    end
    depth_buffer && (depth_bits = 32)
    if stencil_buffer
        depth_bits = 24
        stencil_bits = 8
    end
    float_buffer && (color_bits = 16)

    GLFW.WindowHint(GLFW.RED_BITS,     color_bits)
    GLFW.WindowHint(GLFW.GREEN_BITS,   color_bits)
    GLFW.WindowHint(GLFW.BLUE_BITS,    color_bits)
    GLFW.WindowHint(GLFW.ALPHA_BITS,   color_bits)
    GLFW.WindowHint(GLFW.STENCIL_BITS, stencil_bits)
    GLFW.WindowHint(GLFW.DEPTH_BITS,   depth_bits)
    GLFW.WindowHint(GLFW.VISIBLE,      false)
    GLFW.WindowHint(GLFW.RESIZABLE,    resizable)

    glfw_wnd = GLFW.CreateWindow(wsize..., caption)

    if float_buffer
        float_mode = GLboolean(false)
        @c glGetBooleanv(GL_RGBA_FLOAT_MODE, &float_mode)
        !float_mode && (float_buffer = false)
    end

    GLFW.SetInputMode(glfw_wnd, GLFW.CURSOR, GLFW.CURSOR_NORMAL)

    fbsize = GLFW.GetFramebufferSize(glfw_wnd)
    glViewport(0, 0, fbsize...)

    GLFW.MakeContextCurrent(glfw_wnd)

    (glfw_wnd, background)
end

function runloop(::Type{T}) where {T <: WindowConfig}
    !_glfw_initialized && glfw_init()
    (glfw_wnd, background) = create_glfw_window()
    ctx = get(_ctx_store, T, Ctx(nothing, nothing, glfw_wnd, background))
    runloop(T, ctx)
end

function runloop(::Type{T}, ctx::Ctx) where {T <: WindowConfig}
    if ctx.app === nothing
        ctx.app = Ref(T(ctx))
        mainloop(ctx)
    else
        ctx.app[] = T(ctx)
    end
    ctx
end

# module Shaders.MGL
