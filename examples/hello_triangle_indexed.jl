using Shaders.NanoGUI

import .NanoGUI: draw_contents, keyboard_event
using ModernGL
using CSyntax

GLSL(src) = string("#version 330 core\n", src)

struct MyCanvas <: NanoGUI.Canvas
    destructor
end

function draw_contents(canvas::MyCanvas)
    (CHK ∘ glDrawElements)(GL_TRIANGLES, 6, GL_UNSIGNED_INT, C_NULL)
end

# code from https://learnopengl.com/Getting-started/Hello-Triangle
function MyCanvas()
    vertexSource = GLSL("""
layout (location = 0) in vec3 aPos;
void main() {
    gl_Position = vec4(aPos.x, aPos.y, aPos.z, 1.0);
}
    """)

    vertexShader = glCreateShader(GL_VERTEX_SHADER)
    (CHK ∘ glShaderSource)(vertexShader, 1, (Ref ∘ pointer)(vertexSource), C_NULL)
    (CHK ∘ glCompileShader)(vertexShader)

    fragmentSource = GLSL("""
out vec4 FragColor;
void main() {
    FragColor = vec4(1.0f, 0.5f, 0.2f, 1.0f);
}
    """)

    fragmentShader = glCreateShader(GL_FRAGMENT_SHADER)
    @c (CHK ∘ glShaderSource)(fragmentShader, 1, (Ref ∘ pointer)(fragmentSource), C_NULL)
    (CHK ∘ glCompileShader)(fragmentShader)

    shaderProgram = glCreateProgram()
    (CHK ∘ glAttachShader)(shaderProgram, vertexShader)
    (CHK ∘ glAttachShader)(shaderProgram, fragmentShader)
    (CHK ∘ glLinkProgram)(shaderProgram)

    (CHK ∘ glDeleteShader)(vertexShader)
    (CHK ∘ glDeleteShader)(fragmentShader)

    vertices = Cfloat[
         0.5,  0.5, 0.0, # top right
         0.5, -0.5, 0.0, # bottom right
        -0.5, -0.5, 0.0, # bottom left
        -0.5,  0.5, 0.0, # top left
    ]

    indices = Cuint[
        0, 1, 3, # first Triangle
        1, 2, 3, # second Triangle
    ]

    vao = GLuint(0)
    vbo = GLuint(0)
    ebo = GLuint(0)

    @c (CHK ∘ glGenVertexArrays)(1, &vao)
    @c (CHK ∘ glGenBuffers)(1, &vbo)
    @c (CHK ∘ glGenBuffers)(1, &ebo)

    (CHK ∘ glBindVertexArray)(vao)

    (CHK ∘ glBindBuffer)(GL_ARRAY_BUFFER, vbo)
    (CHK ∘ glBufferData)(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW)

    (CHK ∘ glBindBuffer)(GL_ELEMENT_ARRAY_BUFFER, ebo)
    (CHK ∘ glBufferData)(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW)

    aPos = glGetAttribLocation(shaderProgram, "aPos") # layout (location = 0) in vec3 aPos
    (CHK ∘ glVertexAttribPointer)(aPos, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(Cfloat), C_NULL)
    (CHK ∘ glEnableVertexAttribArray)(aPos)

    (CHK ∘ glBindBuffer)(GL_ARRAY_BUFFER, aPos)

    (CHK ∘ glBindVertexArray)(aPos)

    (CHK ∘ glUseProgram)(shaderProgram)
    (CHK ∘ glBindVertexArray)(vao)

    function destructor()
        (CHK ∘ glDeleteProgram)(shaderProgram)
        @c (CHK ∘ glDeleteVertexArrays)(1, &vao)
        @c (CHK ∘ glDeleteBuffers)(1, &vbo)
        @c (CHK ∘ glDeleteBuffers)(1, &ebo)
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

NanoGUI.mainloop(MyApplication)
