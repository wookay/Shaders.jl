function init(app)
    #glfwSetErrorCallback
    if !GLFW.Init()
        throw(RuntimeError("Could not initialize GLFW!"))
    end
    glfwSetTime(0)
end

function mainloop(app, refresh::Float64)
    mainloop_active = true

    function mainloop_iteration()
        num_screens = 0
        if !app.screen.visible
        elseif GLFW.WindowShouldClose(app.screen.glfw_window)
            set_visible(app.screen, false)
        else
            num_screens += 1
            draw_all(app.screen)
        end
        if iszero(num_screens)
            mainloop_active = false
            return
        end
        GLFW.WaitEvents()
    end

    quantum::Float32 = 0.0
    quantum_count::Csize_t = 1
    if refresh >= 0
        quantum = microseconds(refresh * 1000)
        while quantum > 50_000
            quantum /= 2
            quantum_count *= 2
        end
    else
        quantum = microseconds(50_000) # 50ms
        quantum_count = typemax(Csize_t)
    end
    refresh_thread = Threads.@spawn begin
        while true
            for i in 1:quantum_count
                !mainloop_active && return
                sleep(quantum * 1e-6)
                for screen in screens
                    redraw(screen)
                end
            end
        end
    end
    while mainloop_active
        mainloop_iteration()
    end
    GLFW.PollEvents()
end

function shutdown(app)
    GLFW.DestroyWindow(app.screen.glfw_window)
    GLFW.Terminate()
end
