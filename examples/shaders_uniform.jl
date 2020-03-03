using Shaders.NanoGUI

import .NanoGUI: draw_contents, keyboard_event
using ModernGL
using CSyntax

GLSL(src) = string("#version 330 core\n", src)

struct MyCanvas <: NanoGUI.Canvas
    destructor
    shaderProgram
end

function draw_contents(canvas::MyCanvas)
    timeValue = glfwGetTime()
    greenValue = sin(timeValue) / 2.0 + 0.5
    vertexColorLocation = glGetUniformLocation(canvas.shaderProgram, "ourColor")
    (CHK ∘ glUniform4f)(vertexColorLocation, 0.0, greenValue, 0.0, 1.0)
    (CHK ∘ glDrawArrays)(GL_TRIANGLES, 0, 3)
end

# code from https://learnopengl.com/Getting-started/Shaders
function MyCanvas()
    vertexSource = GLSL("""
layout (location = 0) in vec3 aPos;
void main() {
    gl_Position = vec4(aPos, 1.0);
}
    """)

    vertexShader = glCreateShader(GL_VERTEX_SHADER)
    (CHK ∘ glShaderSource)(vertexShader, 1, (Ref ∘ pointer)(vertexSource), C_NULL)
    (CHK ∘ glCompileShader)(vertexShader)

    fragmentSource = GLSL("""
out vec4 FragColor;
uniform vec4 ourColor;
void main() {
    FragColor = ourColor;
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
         0.5, -0.5, 0.0, # bottom right
        -0.5, -0.5, 0.0, # bottom left
         0.0,  0.5, 0.0, # top
    ]

    vao = GLuint(0)
    vbo = GLuint(0)

    @c (CHK ∘ glGenVertexArrays)(1, &vao)
    @c (CHK ∘ glGenBuffers)(1, &vbo)

    (CHK ∘ glBindVertexArray)(vao)

    (CHK ∘ glBindBuffer)(GL_ARRAY_BUFFER, vbo)
    (CHK ∘ glBufferData)(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW)

    aPos = glGetAttribLocation(shaderProgram, "aPos") # layout (location = 0) in vec3 aPos
    (CHK ∘ glVertexAttribPointer)(aPos, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(Cfloat), C_NULL)
    (CHK ∘ glEnableVertexAttribArray)(aPos)

    (CHK ∘ glBindVertexArray)(vao)

    (CHK ∘ glUseProgram)(shaderProgram)

    function destructor()
        (CHK ∘ glDeleteProgram)(shaderProgram)
        @c (CHK ∘ glDeleteVertexArrays)(1, &vao)
        @c (CHK ∘ glDeleteBuffers)(1, &vbo)
    end

    MyCanvas(destructor, shaderProgram)
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
