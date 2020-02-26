function draw_all(app::T) where {T <: Application}
    draw_all(app.screen)
end

function set_visible(app::T, visible::Bool) where {T <: Application}
    set_visible(app.screen, visible)
end
