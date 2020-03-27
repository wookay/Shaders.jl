using Shaders.MGL # CHK GLSL WindowConfig Program Buffer VertexArray create render run
import .MGL: render
using ModernGL

struct HelloWorld <: WindowConfig
    ctx
    vao
end

function HelloWorld(ctx)
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
         0.5 -0.5 0.0 # bottom right
        -0.5 -0.5 0.0 # bottom left
         0.0  0.5 0.0 # top
    ]
    vao = (create ∘ VertexArray)(ctx, prog, vertices, "aPos")
    HelloWorld(ctx, vao)
end

function render(w::HelloWorld, time, frametime)
    render(w.vao, ModernGL.GL_TRIANGLES)
    green = sin(time) / 2.0 + 0.5
    vertexColorLocation = glGetUniformLocation(w.vao.prog.id, "ourColor")
    (CHK ∘ glUniform4f)(vertexColorLocation, 0.0, green, 0.0, 1.0)
end

run(HelloWorld)
