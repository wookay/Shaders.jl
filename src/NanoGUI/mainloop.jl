function init()
    #glfwSetErrorCallback
    if !GLFW.Init()
        throw(RuntimeError("Could not initialize GLFW!"))
    end
    glfwSetTime(0)
end

function microseconds(μs)
    μs
end

function mainloop(app, refresh::Float64=1000(1 / 60), closenotify=Condition())
    NanoGUI.init()
    draw_all(app)
    set_visible(app, true)

    mainloop_active = true

    function mainloop_iteration(app) # mainloop_active
        run = true
        if !app.screen.visible
            run = false
        elseif GLFW.WindowShouldClose(app.screen.glfw_window)
            run = false
            set_visible(app, false)
        else
            draw_all(app.screen)
        end
        if !run
            mainloop_active = false
            dispose(app.screen)
            GLFW.DestroyWindow(app.screen.glfw_window)
            GLFW.Terminate()
            notify(closenotify)
        end
    end

    quantum_ms::Float32 = 0.0f0
    quantum_count::Csize_t = 1
    if refresh >= 0
        quantum_ms = microseconds(refresh * 1000)
        while quantum_ms > 50_000
            quantum_ms /= 2
            quantum_count *= 2
        end
    else
        quantum_ms = microseconds(50_000) # 50ms
        quantum_count = typemax(Csize_t)
    end
    quantum = quantum_ms * 1e-6
    refresh_task = @async begin
        while true
            for i in 1:quantum_count
                !mainloop_active && return
                sleep(quantum)
                redraw(app.screen)
            end
        end
    end
    mainloop_task = @async while mainloop_active
        mainloop_iteration(app)
        yield()
        GLFW.WaitEvents(quantum)
    end
    iszero(Base.JLOptions().isinteractive) && wait(closenotify)
    (mainloop_task, refresh_task)
end
