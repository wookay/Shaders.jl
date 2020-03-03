using Shaders.NanoGUI

import .NanoGUI: draw_contents, keyboard_event
using ModernGL
using CSyntax
using StaticArrays
using Rotations

GLSL(src) = string("#version 150 core\n", src)

mutable struct MyCanvas <: NanoGUI.Canvas
    destructor
    uniTrans::GLint
    trans::SMatrix{4,4,Cfloat}
end

function draw_contents(canvas::MyCanvas)
    trans = canvas.trans # rotate(trans, sin(glfwGetTime()) * 2.0, Vector3f(0.0, 0.0, 1.0))
    (CHK ∘ glUniformMatrix4fv)(canvas.uniTrans, 1, GL_FALSE, Ref(trans))
    (CHK ∘ glDrawElements)(GL_TRIANGLES, 12*3, GL_UNSIGNED_INT, C_NULL)
end

# code from https://github.com/zuck/opengl-examples/blob/master/Examples/Transformations/main.cpp
function MyCanvas()
    vao = GLuint(0)
    @c (CHK ∘ glGenVertexArrays)(1, &vao)
    (CHK ∘ glBindVertexArray)(vao)

    vbo = GLuint(0)
    @c (CHK ∘ glGenBuffers)(1, &vbo)
    (CHK ∘ glBindBuffer)(GL_ARRAY_BUFFER, vbo)

    vertices = Cfloat[
      # Position    Color          Texcoords
        -0.5,  0.5, 1.0, 0.0, 0.0, 0.0, 0.0, # Top-left
         0.5,  0.5, 0.0, 1.0, 0.0, 1.0, 0.0, # Top-right
         0.5, -0.5, 0.0, 0.0, 1.0, 1.0, 1.0, # Bottom-right
        -0.5, -0.5, 1.0, 1.0, 1.0, 0.0, 1.0, # Bottom-left
    ]
    (CHK ∘ glBufferData)(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW)

    ebo = GLuint(0)
    @c (CHK ∘ glGenBuffers)(1, &ebo)
    (CHK ∘ glBindBuffer)(GL_ELEMENT_ARRAY_BUFFER, ebo)

    elements = GLuint[    # 3 * 12
        3, 2, 6, 6, 7, 3,
        4, 5, 1, 1, 0, 4,
        4, 0, 3, 3, 7, 4,
        1, 5, 6, 6, 2, 1,
        0, 1, 2, 2, 3, 0,
        7, 6, 5, 5, 4, 7
    ]
    (CHK ∘ glBufferData)(GL_ELEMENT_ARRAY_BUFFER, sizeof(elements), elements, GL_STATIC_DRAW)

    vertexSource = GLSL("""
        uniform mat4 mvp;
        in vec3 position;
        in vec3 color;
        out vec4 frag_color;
        void main() {
            frag_color = vec4(color, 1.0);
            gl_Position = mvp * vec4(position, 1.0);
        }
    """)

    vertexShader = glCreateShader(GL_VERTEX_SHADER)
    (CHK ∘ glShaderSource)(vertexShader, 1, (Ref ∘ pointer)(vertexSource), C_NULL)
    (CHK ∘ glCompileShader)(vertexShader)

    fragmentSource = GLSL("""
        out vec4 color;
        in vec4 frag_color;
        void main() {
            color = frag_color;
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

    positions = Cfloat[ # 3*8
        -1.,  1.,  1., -1., -1.,  1.,
         1., -1.,  1.,  1.,  1.,  1.,
        -1.,  1., -1., -1., -1., -1.,
         1., -1., -1.,  1.,  1., -1.,
    ]
    posAttrib = glGetAttribLocation(shaderProgram, "position")
    glVertexAttribPointer(posAttrib, 2, GL_FLOAT, GL_FALSE, 7 * sizeof(GLfloat), C_NULL)
    glEnableVertexAttribArray(posAttrib)

    colors = Cfloat[ # 3*8
        0, 1, 1, 0, 0, 1,
        1, 0, 1, 1, 1, 1,
        0, 1, 0, 0, 0, 0,
        1, 0, 0, 1, 1, 0,
    ]
    colAttrib = glGetAttribLocation(shaderProgram, "color")
    glVertexAttribPointer(colAttrib, 3, GL_FLOAT, GL_FALSE, 7 * sizeof(GLfloat), Ptr{Cvoid}(2 * sizeof(GLfloat)))
    glEnableVertexAttribArray(colAttrib)

    function destructor()
        (CHK ∘ glDeleteProgram)(shaderProgram)
        (CHK ∘ glDeleteShader)(fragmentShader)
        (CHK ∘ glDeleteShader)(vertexShader)
        @c (CHK ∘ glDeleteBuffers)(1, &ebo)
        @c (CHK ∘ glDeleteBuffers)(1, &vbo)
        @c (CHK ∘ glDeleteVertexArrays)(1, &vao)
    end

    uniTrans = glGetUniformLocation(shaderProgram, "mvp")
    trans = one(SMatrix{4,4})
    MyCanvas(destructor, uniTrans, trans)
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
