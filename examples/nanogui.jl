using Shaders.NanoGUI # GLFW

import .NanoGUI: draw_contents, draw, keyboard_event
using ModernGL # glDrawArrays
using CSyntax

struct MyCanvas <: NanoGUI.Canvas
    children::Vector{Widget}
    destructor
end

function draw_contents(canvas::MyCanvas)
    glDrawArrays(GL_TRIANGLES, 0, 3)
end

GLSL(src) = """
#version 150 core
$src
"""

function MyCanvas(parent::Window)
    vao = GLuint(0)
    @c glGenVertexArrays(1, &vao)
    glBindVertexArray(vao)

    vbo = GLuint(0)
    @c glGenBuffers(1, &vbo)
    glBindBuffer(GL_ARRAY_BUFFER, vbo)

    vertices = Cfloat[
         0.0,  0.5,
         0.5, -0.5,
        -0.5, -0.5,
    ]

    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW)

    vertexSource = GLSL("""
in vec2 position;

void main() {
    gl_Position = vec4(position, 0.0, 1.0);
}
    """)

    vertexShader = glCreateShader(GL_VERTEX_SHADER)
    glShaderSource(vertexShader, 1, [pointer(vertexSource)], C_NULL)
    glCompileShader(vertexShader)

    fragmentSource = GLSL("""
out vec4 outColor;

void main() {
    outColor = vec4(1.0f, 1.0f, 1.0f, 1.0f);
}
    """)

    fragmentShader = glCreateShader(GL_FRAGMENT_SHADER)
    @c glShaderSource(fragmentShader, 1, [pointer(fragmentSource)], C_NULL)
    glCompileShader(fragmentShader)

    shaderProgram = glCreateProgram()
    glAttachShader(shaderProgram, vertexShader)
    glAttachShader(shaderProgram, fragmentShader)
    glBindFragDataLocation(shaderProgram, 0, "outColor")
    glLinkProgram(shaderProgram)
    glUseProgram(shaderProgram)

    posAttrib = glGetAttribLocation(shaderProgram, "position")
    glEnableVertexAttribArray(posAttrib)
    glVertexAttribPointer(posAttrib, 2, GL_FLOAT, GL_FALSE, 0, C_NULL)

    function destructor()
        glDeleteProgram(shaderProgram)
        glDeleteShader(fragmentShader)
        glDeleteShader(vertexShader)
        @c glDeleteBuffers(1, &vbo)
        @c glDeleteVertexArrays(1, &vao)
    end

    canvas = MyCanvas([], destructor)
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
    MyCanvas(window)
    MyApplication(screen)
end

app = MyApplication()

NanoGUI.init()

draw_all(app)
set_visible(app, true)

NanoGUI.mainloop(app, 1000(1 / 60))
NanoGUI.shutdown(app)
