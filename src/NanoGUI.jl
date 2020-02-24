module NanoGUI

using GLFW
using ModernGL
using Colors
using CSyntax
using LinearAlgebra
using StaticArrays

export Vector2i
include("NanoGUI/glfw.jl")

export Screen, set_visible, perform_layout
include("NanoGUI/screen.jl")

export RenderPass, VertexShader, FragmentShader, Shader
export None
export set_buffer, draw_all
include("NanoGUI/shader.jl")

export NVGcontext
include("NanoGUI/application.jl")

include("NanoGUI/mainloop.jl")

end # NanoGUI
