using Shaders.NanoGUI

import .NanoGUI: draw_contents, keyboard_event
using ModernGL
using CSyntax

GLSL(src) = string("#version 150 core\n", src)

struct MyCanvas <: NanoGUI.Canvas
    destructor
end

function draw_contents(canvas::MyCanvas)
    (CHK ∘ glDrawArrays)(GL_TRIANGLES, 0, 3)
end

# code from https://github.com/zuck/opengl-examples/blob/master/Examples/Triangle/main.cpp
function MyCanvas()
    vao = GLuint(0)
    @c (CHK ∘ glGenVertexArrays)(1, &vao)
    (CHK ∘ glBindVertexArray)(vao)

    vbo = GLuint(0)
    @c (CHK ∘ glGenBuffers)(1, &vbo)
    (CHK ∘ glBindBuffer)(GL_ARRAY_BUFFER, vbo)

    vertices = Cfloat[
         0.0,  0.5,
         0.5, -0.5,
        -0.5, -0.5,
    ]

    (CHK ∘ glBufferData)(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW)

    vertexSource = GLSL("""
in vec2 position;

void main() {
    gl_Position = vec4(position, 0.0, 1.0);
}
    """)

    vertexShader = glCreateShader(GL_VERTEX_SHADER)
    (CHK ∘ glShaderSource)(vertexShader, 1, (Ref ∘ pointer)(vertexSource), C_NULL)
    (CHK ∘ glCompileShader)(vertexShader)

    fragmentSource = GLSL("""
out vec4 outColor;

void main() {
    outColor = vec4(1.0f, 0.5f, 0.2f, 1.0f);
}
    """)

    fragmentShader = glCreateShader(GL_FRAGMENT_SHADER)
    @c (CHK ∘ glShaderSource)(fragmentShader, 1, (Ref ∘ pointer)(fragmentSource), C_NULL)
    (CHK ∘ glCompileShader)(fragmentShader)

    shaderProgram = glCreateProgram()
    (CHK ∘ glAttachShader)(shaderProgram, vertexShader)
    (CHK ∘ glAttachShader)(shaderProgram, fragmentShader)
    (CHK ∘ glBindFragDataLocation)(shaderProgram, 0, "outColor")
    (CHK ∘ glLinkProgram)(shaderProgram)
    (CHK ∘ glUseProgram)(shaderProgram)

    posAttrib = glGetAttribLocation(shaderProgram, "position")
    (CHK ∘ glVertexAttribPointer)(posAttrib, 2, GL_FLOAT, GL_FALSE, 0, C_NULL)
    (CHK ∘ glEnableVertexAttribArray)(posAttrib)

    function destructor()
        (CHK ∘ glDeleteProgram)(shaderProgram)
        (CHK ∘ glDeleteShader)(fragmentShader)
        (CHK ∘ glDeleteShader)(vertexShader)
        @c (CHK ∘ glDeleteBuffers)(1, &vbo)
        @c (CHK ∘ glDeleteVertexArrays)(1, &vao)
    end

    MyCanvas(destructor)
end

function keyboard_event(screen::Screen, key, scancode, action, modifiers)::Bool
    if key == GLFW.KEY_ESCAPE && action == GLFW.PRESS
        set_visible(screen, false)
        return true
    end
    return false
end

struct MyApplication <: NanoGUI.Application
    screen::Screen
end

function MyApplication()
    screen = NanoGUI.Screen(Vector2i(800, 600), caption="NanoGUI Test", resizable=false)
    window = NanoGUI.Window(screen, caption="Canvas widget demo")
    add_child(window, MyCanvas())
    MyApplication(screen)
end

app = MyApplication()
NanoGUI.mainloop(app)
