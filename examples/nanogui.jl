using Shaders.NanoGUI # GLFW

import .NanoGUI: draw_contents, draw, keyboard_event

struct MyCanvas <: NanoGUI.Canvas
    children::Vector{Widget}
    wsize::Vector2i
    shader::Shader
end

function perspective(fov, near, far, aspect = 1)
    nmf = near - far
    f = 1 / tan(fov)/2
    [f/aspect 0                    0  0
            0 f                    0  0
            0 0     (near + far)/nmf -1
            0 0 (2 * far * near)/nmf  0]
end

function draw_contents(canvas::MyCanvas)
    @info :draw_contents canvas
    m_rotation = 0
    m_size = canvas.wsize
    # look_at perspective
    mvp = Cfloat[1 1 1 1
                 1 1 1 1
                 1 1 1 1
                 1 1 1 1]
    set_uniform(canvas.shader, "mvp", mvp)
    begin_shader(canvas.shader)
    draw_array(Triangle, 0, 12*3, true)
    end_shader(canvas.shader)
end

function MyCanvas(parent::Window)
    color_targets = [parent.screen]
    depth_target = C_NULL
    stencil_target = C_NULL
    blit_target = C_NULL
    clear = false
    render_pass = RenderPass(color_targets, depth_target, stencil_target, blit_target, clear)
    shader = Shader(render_pass, "a_simple_shader", VertexShader("""#version 330
    uniform mat4 mvp;
    in vec3 position;
    in vec3 color;
    out vec4 frag_color;
    void main() {
        frag_color = vec4(color, 1.0);
        gl_Position = mvp * vec4(position, 1.0);
    }"""), FragmentShader("""#version 330
    out vec4 color;
    in vec4 frag_color;
    void main() {
        color = frag_color;
    }"""), None)

    indices = [
        3, 2, 6, 6, 7, 3,
        4, 5, 1, 1, 0, 4,
        4, 0, 3, 3, 7, 4,
        1, 5, 6, 6, 2, 1,
        0, 1, 2, 2, 3, 0,
        7, 6, 5, 5, 4, 7
    ]

    positions = [
        -1.0, 1.0, 1.0, -1.0, -1.0, 1.0,
        1.0, -1.0, 1.0, 1.0, 1.0, 1.0,
        -1.0, 1.0, -1.0, -1.0, -1.0, -1.0,
        1.0, -1.0, -1.0, 1.0, 1.0, -1.0
    ]

    colors = [
        0, 1, 1, 0, 0, 1,
        1, 0, 1, 1, 1, 1,
        0, 1, 0, 0, 0, 0,
        1, 0, 0, 1, 1, 0
    ]
    set_buffer(shader, "indices", UInt32, 1, [3*12, 1, 1], indices)
    set_buffer(shader, "position", Float32, 2, [8, 3, 1], positions)
    set_buffer(shader, "color", Float32, 2, [8, 3, 1], colors)
    wsize = parent.wsize
    canvas = MyCanvas([], wsize, shader)
    add_child(parent, canvas)
end

struct MyApplication <: NanoGUI.Application
    screen::Screen
end

function draw(app::MyApplication, ctx::NVGcontext)
    draw(app.screen, ctx)
end

function keyboard_event(screen::Screen, key, scancode, action, modifiers)::Bool
    if key == GLFW.KEY_ESCAPE && action == GLFW.PRESS
        set_visible(screen, false)
        return true
    end
    return false
end

function MyApplication()
    screen = NanoGUI.Screen(Vector2i(800, 600), caption="NanoGUI Test", resizable=false)
    window = NanoGUI.Window(screen, caption="Canvas widget demo")
    canvas = MyCanvas(window)
    perform_layout(screen)
    MyApplication(screen)
end

app = MyApplication()

NanoGUI.init()

draw_all(app)
set_visible(app, true)

NanoGUI.mainloop(app, 1000(1 / 60))
NanoGUI.shutdown(app)
