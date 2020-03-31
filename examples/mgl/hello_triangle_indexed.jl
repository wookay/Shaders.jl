using Shaders.MGL # CHK GLSL WindowConfig Program Buffer VertexArray create render run
import .MGL: render
using ModernGL

struct HelloTriangle <: WindowConfig
    ctx
    vao
end

function HelloTriangle(ctx)
    prog = (create ∘ Program)(
        vertex_shader = GLSL("""
layout (location = 0) in vec3 aPos;
void main() {
    gl_Position = vec4(aPos, 1.0);
}
    """),
        fragment_shader = GLSL("""
out vec4 FragColor;
uniform vec4 ourColor;
void main() {
    FragColor = ourColor;
}
    """)
    )

    vertices = [
         0.5  0.5 0.0 # top right
         0.5 -0.5 0.0 # bottom right
        -0.5 -0.5 0.0 # bottom left
        -0.5  0.5 0.0 # top left
    ]

    indices = [
        0 1 3 # first Triangle
        1 2 3 # second Triangle
    ]
    vao = (create ∘ VertexArray)(ctx, prog, (aPos=vertices,), IndexBuffer{Cuint}(indices))
    HelloTriangle(ctx, vao)
end

function render(w::HelloTriangle, time, frametime)
    render(w.vao, ModernGL.GL_TRIANGLES, 6, ModernGL.GL_UNSIGNED_INT)
end

run(HelloTriangle)
