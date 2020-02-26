mutable struct Screen <: Widget
    children::Vector{Widget}
    wsize::Vector2i
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
    background::RGBA
    shutdown_glfw::Bool
    fullscreen::Bool
    depth_buffer::Bool
    stencil_buffer::Bool
    float_buffer::Bool
    redraw::Bool
    visible::Bool
end

struct Window <: Widget
    children::Vector{Widget}
    wsize::Vector2i
    screen::Screen
    caption::AbstractString
end

function Window(screen::Screen; caption::AbstractString = "")
    wsize = screen.wsize
    window = Window([], wsize, screen, caption)
    add_child(screen, window)
end

# nanogui-mitsuba/src/screen.cpp
function Screen(wsize::Vector2i, background::RGBA, caption::String, resizable::Bool, fullscreen::Bool, depth_buffer::Bool, stencil_buffer::Bool, float_buffer::Bool, gl_major::UInt, gl_minor::UInt)::Screen
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

    children = Vector{Widget}()
    glfw_window = GLFW.CreateWindow(wsize..., caption)

    if float_buffer
        float_mode = GLboolean(false)
        @c glGetBooleanv(GL_RGBA_FLOAT_MODE, &float_mode)
        !float_mode && (float_buffer = false)
    end

    GLFW.MakeContextCurrent(glfw_window)
    GLFW.SetInputMode(glfw_window, GLFW.CURSOR, GLFW.CURSOR_NORMAL)

    fbsize = GLFW.GetFramebufferSize(glfw_window)
    glViewport(0, 0, fbsize...)

    glClearColor(background)

    GLFW.SwapInterval(0)
    GLFW.SwapBuffers(glfw_window)
    GLFW.PollEvents()

    ctx = NVGcontext()
    shutdown_glfw = true
    screen = initialize(children, wsize, glfw_window, ctx, background, shutdown_glfw, fullscreen, depth_buffer, stencil_buffer, float_buffer)
#=
    glfwSetCursorPosCallback
    glfwSetMouseButtonCallback
    glfwSetCharCallback
    glfwSetDropCallback
    glfwSetScrollCallback
    glfwSetFramebufferSizeCallback
    glfwSetWindowFocusCallback
=#
    key_callback = function (_, key, scancode, action, mods)
        !screen.process_events && return
        screen.last_interaction = glfwGetTime()
        screen.redraw |= keyboard_event(screen, key, scancode, action, mods)
    end
    GLFW.SetKeyCallback(screen.glfw_window, key_callback)
    screen
end

function Screen(wsize::Vector2i; background::RGBA = RGBA(0.3, 0.3, 0.32, 1.), caption::String = "Unnamed", resizable::Bool = true, fullscreen::Bool = false, depth_buffer::Bool = true, stencil_buffer::Bool = true, float_buffer::Bool = false, gl_major::UInt = UInt(3), gl_minor::UInt = UInt(2))::Screen
    Screen(wsize::Vector2i, background, caption::String, resizable::Bool, fullscreen::Bool, depth_buffer::Bool, stencil_buffer::Bool, float_buffer::Bool, gl_major::UInt, gl_minor::UInt)
end

function initialize(children::Vector{Widget}, wsize::Vector2i, glfw_window::GLFW.Window, ctx::NVGcontext, background::RGBA, shutdown_glfw::Bool, fullscreen::Bool, depth_buffer::Bool, stencil_buffer::Bool, float_buffer::Bool)::Screen
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
        children::Vector{Widget},
        wsize::Vector2i,
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
        background::RGBA,
        shutdown_glfw::Bool,
        fullscreen::Bool,
        depth_buffer::Bool,
        stencil_buffer::Bool,
        float_buffer::Bool,
        redraw::Bool,
        visible::Bool)
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

function keyboard_event(_, key, scancode, action, modifiers)
    false
end

function draw_all(screen::Screen)
    if screen.redraw
        screen.redraw = false

        GLFW.MakeContextCurrent(screen.glfw_window)

        # @c GLFW.GetFramebufferSize(screen.glfw_window, &m_fbsize[1], &m_fbsize[2]);
        # @c GLFW.GetWindowSize(screen.glfw_window, &m_size[1], &m_size[2]);
        #if m_size[0]
        #    screen.m_pixel_ratio = (float) m_fbsize[0] / (float) m_size[0];
        #end

        (CHK ∘ glViewport)(0, 0, screen.fbsize...)

        draw_contents(screen)
        draw_widgets(screen)

        GLFW.SwapBuffers(screen.glfw_window)
    end
end

function draw_contents(screen::Screen)
    glClearColor(screen.background)
end

function draw_widgets(screen::Screen)
    draw(screen, screen.nvg_context)
end
