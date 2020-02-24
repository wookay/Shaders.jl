abstract type Application end
abstract type Canvas end

function draw_contents
end

function draw_all(app)
    draw_all(app.screen)
end

function set_visible(app, visible)
    set_visible(app.screen, visible)
end
