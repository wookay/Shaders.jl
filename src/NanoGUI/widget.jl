abstract type Application end
abstract type Widget end
abstract type Canvas <: Widget end

struct NVGcontext
end

function add_child(parent::P, child::C) where {P <: Widget, C <: Widget}
    push!(parent.children, child)
    child
end

function set_size(widget::W, wsize::Vector2i) where {W <: Widget}
end

function draw(widget::W, ctx::NVGcontext) where {W <: Widget}
    isempty(widget.children) && return
    for child in widget.children
        draw(child, ctx)
    end
end

function draw(canvas::Canvas, ctx::NVGcontext)
    begin_render_pass(canvas.shader.render_pass)
    draw_contents(canvas)
    end_render_pass(canvas.shader.render_pass)
end
