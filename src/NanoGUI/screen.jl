struct NVGcontext
end

mutable struct Screen
    glfw_window::GLFW.Window
    nvg_context::NVGcontext
    fbsize::Vector2i
    pixel_ratio::Cfloat
    mouse_state::Cint
    modifiers::Cint
    mouse_pos::Vector2i
    drag_active::Bool
    last_interaction::Cdouble
    process_events::Bool
    shutdown_glfw::Bool
    fullscreen::Bool
    depth_buffer::Bool
    stencil_buffer::Bool
    float_buffer::Bool
    redraw::Bool
    visible::Bool
    wsize::Vector2i
end

struct Window
    parent
    caption
end

function Window(parent; caption::String = "")
    Window(parent, caption)
end

# nanogui-mitsuba/src/screen.cpp
function Screen(wsize::Vector2i, caption::String, resizable::Bool, fullscreen::Bool, depth_buffer::Bool, stencil_buffer::Bool, float_buffer::Bool, gl_major::UInt, gl_minor::UInt)::Screen
    GLFW.WindowHint(GLFW.CLIENT_API, GLFW.OPENGL_API)

    GLFW.WindowHint(GLFW.CONTEXT_VERSION_MAJOR, gl_major)
    GLFW.WindowHint(GLFW.CONTEXT_VERSION_MINOR, gl_minor)
    GLFW.WindowHint(GLFW.OPENGL_FORWARD_COMPAT, true)
    GLFW.WindowHint(GLFW.OPENGL_PROFILE, GLFW.OPENGL_CORE_PROFILE)

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

    GLFW.WindowHint(GLFW.RED_BITS, color_bits)
    GLFW.WindowHint(GLFW.GREEN_BITS, color_bits)
    GLFW.WindowHint(GLFW.BLUE_BITS, color_bits)
    GLFW.WindowHint(GLFW.ALPHA_BITS, color_bits)
    GLFW.WindowHint(GLFW.STENCIL_BITS, stencil_bits)
    GLFW.WindowHint(GLFW.DEPTH_BITS, depth_bits)
    GLFW.WindowHint(GLFW.VISIBLE, false)
    GLFW.WindowHint(GLFW.RESIZABLE, resizable)

    glfw_window = glfwCreateWindow(wsize..., caption, C_NULL, C_NULL)

    if float_buffer
        float_mode = GLboolean(false)
        @c glGetBooleanv(GL_RGBA_FLOAT_MODE, &float_mode)
        !float_mode && (float_buffer = false)
    end

    GLFW.MakeContextCurrent(glfw_window)
    GLFW.SetInputMode(glfw_window, GLFW.CURSOR, GLFW.CURSOR_NORMAL)

    fbsize = GLFW.GetFramebufferSize(glfw_window)
    glViewport(0, 0, fbsize...)

    background = RGBA(0.3, 0.3, 0.32, 1.)
    glClearColor(background)

    GLFW.SwapInterval(0)
    GLFW.SwapBuffers(glfw_window)
    GLFW.PollEvents()

#=
    glfwSetCursorPosCallback
    glfwSetMouseButtonCallback
    glfwSetKeyCallback
    glfwSetCharCallback
    glfwSetDropCallback
    glfwSetScrollCallback
    glfwSetFramebufferSizeCallback
    glfwSetWindowFocusCallback
=#
    ctx = NVGcontext()
    shutdown_glfw = true
    initialize(glfw_window, ctx, shutdown_glfw, fullscreen, depth_buffer, stencil_buffer, float_buffer, wsize)
end

function Screen(wsize::Vector2i; caption::String = "Unnamed", resizable::Bool = true, fullscreen::Bool = false, depth_buffer::Bool = true, stencil_buffer::Bool = true, float_buffer::Bool = false, gl_major::UInt = UInt(3), gl_minor::UInt = UInt(2))::Screen
    Screen(wsize::Vector2i, caption::String, resizable::Bool, fullscreen::Bool, depth_buffer::Bool, stencil_buffer::Bool, float_buffer::Bool, gl_major::UInt, gl_minor::UInt)
end

function initialize(glfw_window::GLFW.Window, ctx::NVGcontext, shutdown_glfw::Bool, fullscreen::Bool, depth_buffer::Bool, stencil_buffer::Bool, float_buffer::Bool, wsize::Vector2i)::Screen
    fbsize = Vector2i(GLFW.GetFramebufferSize(glfw_window)...)
    pixel_ratio = get_pixel_ratio(glfw_window)
    visible = GLFW.GetWindowAttrib(glfw_window, GLFW.VISIBLE) != 0
    mouse_pos::Vector2i = (0, 0)
    mouse_state::Cint = modifiers::Cint = 0
    drag_active = false
    last_interaction = glfwGetTime()
    process_events = true
    redraw = true
    Screen(
        glfw_window::GLFW.Window,
        ctx::NVGcontext,
        fbsize::Vector2i,
        pixel_ratio,
        mouse_state,
        modifiers,
        mouse_pos::Vector2i,
        drag_active::Bool,
        last_interaction::Cdouble,
        process_events::Bool,
        shutdown_glfw::Bool,
        fullscreen::Bool,
        depth_buffer::Bool,
        stencil_buffer::Bool,
        float_buffer::Bool,
        redraw::Bool,
        visible::Bool,
        wsize::Vector2i)
end

function get_pixel_ratio(glfw_window::GLFW.Window)::Cfloat
    fbsize = GLFW.GetFramebufferSize(glfw_window)
    wsize = GLFW.GetWindowSize(glfw_window)
    return fbsize[1] / wsize[1]
end

function set_visible(screen::Screen, visible::Bool)
    if screen.visible != visible
        screen.visible = visible
        (visible ? GLFW.ShowWindow : GLFW.HideWindow)(screen.glfw_window)
    end
end

function set_caption(screen::Screen, caption::AbstractString)
    if caption != screen.caption
        GLFW.SetWindowTitle(screen.glfw_window, caption)
        screen.caption = caption
    end
end

function set_size(screen::Screen, wsize::Vector2i)
    screen.wsize = wsize
    GLFW.SetWindowSize(screen.glfw_window, wsize[1] * screen.pixel_ratio, wsize[2] * screen.pixel_ratio)
end

function redraw(screen::Screen)
    if !screen.redraw
        screen.redraw = true
    end
end

function look_at(origin::Vector3f, target::Vector3f, up::Vector3f)
    # dir = norm(target - origin)
    # left = norm(cross(dir, up))
    # new_up = cross(left, dir)
    # column_t = -dot(left, origin) * -dot(new_up, origin) * dot(dir, origin) * 1.0
    # [left, new_up, -dir, column_t]
    [0, 0, 0, 0]
end

function perform_layout(screen::Screen)
end
