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

export Screen, Window, set_visible
include("NanoGUI/screen.jl")

export NVGcontext, draw_all
include("NanoGUI/application.jl")

include("NanoGUI/mainloop.jl")

end # NanoGUI
