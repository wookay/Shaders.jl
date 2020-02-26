"""
NanoGUI

 - https://github.com/wjakob/nanogui
 - https://github.com/elegracer/nanogui-mitsuba
"""
module NanoGUI

export GLFW

using GLFW
using ModernGL
using Colors
using CSyntax
using LinearAlgebra
using StaticArrays

export Vector2i, Vector3f, glfwGetTime
include("NanoGUI/glfw.jl")

export Widget, add_child
include("NanoGUI/widget.jl")

export Screen, Window, set_visible, perform_layout, look_at
include("NanoGUI/screen.jl")

export RenderPass, VertexShader, FragmentShader, Shader
export None
export Triangle
export begin_shader, end_shader, draw_array, set_uniform, set_buffer, draw_all
include("NanoGUI/shader.jl")

export NVGcontext
include("NanoGUI/application.jl")

include("NanoGUI/mainloop.jl")

end # NanoGUI
