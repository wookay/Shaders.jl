using Shaders.MGL # CHK GLSL WindowConfig Program Buffer VertexArray create render run
import .MGL: render
using ModernGL

struct Triangle <: WindowConfig
    ctx
    vao
end

function Triangle(ctx)
    prog = (create ∘ Program)(
        vertex_shader = GLSL("""
in vec2 position;

void main() {
    gl_Position = vec4(position, 0.0, 1.0);
}
    """),
        fragment_shader = GLSL("""
out vec4 outColor;

void main() {
    outColor = vec4(1.0f, 0.5f, 0.2f, 1.0f);
}
    """)
    )

    vertices = [
         0.0  0.5
         0.5 -0.5
        -0.5 -0.5
    ]
    vao = (create ∘ VertexArray)(ctx, prog, vertices, "position")
    Triangle(ctx, vao)
end

function render(w::Triangle, time, frametime)
    render(w.vao, ModernGL.GL_TRIANGLES)
end

run(Triangle)
