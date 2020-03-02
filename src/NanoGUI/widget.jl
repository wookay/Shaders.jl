abstract type Application end
abstract type Widget end
abstract type Canvas <: Widget end

struct NVGcontext
end

function add_child(parent::P, child::C) where {P <: Widget, C <: Widget}
    push!(parent.children, child)
    child
end

function draw(widget::W, ctx::NVGcontext) where {W <: Widget}
    isempty(widget.children) && return
    for child in widget.children
        draw(child, ctx)
    end
end

function dispose(widget::W) where {W <: Widget}
    hasfield(W, :children) && dispose.(widget.children)
    hasfield(W, :destructor) && widget.destructor()
end

function draw(canvas::Canvas, ctx::NVGcontext)
    draw_contents(canvas)
end
