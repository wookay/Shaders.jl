using Shaders.NanoGUI # draw Vector2i

import .NanoGUI: draw_contents

struct MyCanvas <: NanoGUI.Canvas
    parent
    shader::Shader
end

function draw_contents(canvas::MyCanvas)
    shader_begin(canvas.shader)
    draw_array(canvas.shader, Triangle, 0, 12*3, true)
    shader_end(canvas.shader)
end

function MyCanvas(parent)
    color_targets = [parent]
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
    set_buffer(shader.m_buffers, "indices", UInt32, 1, [3*12, 1, 1], indices)
    set_buffer(shader.m_buffers, "position", Float32, 2, [8, 3, 1], positions)
    set_buffer(shader.m_buffers, "color", Float32, 2, [8, 3, 1], colors)
    MyCanvas(parent, shader)
end

struct MyApplication <: NanoGUI.Application
    screen::Screen
end

function draw_contents(app::MyApplication)
end

function MyApplication()
    screen = NanoGUI.Screen(Vector2i(800, 600), caption="NanoGUI Test", resizable=false)
    # window = NanoGUI.Window(screen, caption="Canvas widget demo")
    canvas = MyCanvas(screen)
    perform_layout(screen)
    MyApplication(screen)
end

app = MyApplication()
NanoGUI.init(app)

@info app
draw_all(app)
set_visible(app, true)

NanoGUI.mainloop(app, 1000(1 / 60))
NanoGUI.shutdown(app)
