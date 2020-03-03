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

function get_quantum(refresh::Float64)::Float32
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
    quantum_ms * 1e-6
end

function mainloop(::Type{T}, args...) where {T <: Application}
    NanoGUI.init()
    app = T()
    mainloop(app, args...)
end

function mainloop(app::T, refresh::Float64=1000(1 / 60), closenotify=Condition()) where {T <: Application}
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
            app.screen.glfw_window.handle = C_NULL
            GLFW.Terminate()
            notify(closenotify)
        end
    end

    function refresh_func(app, quantum)
        while mainloop_active
            redraw(app.screen)
            sleep(quantum)
        end
    end

    function mainloop_func(app, quantum)
        draw_all(app)
        set_visible(app, true)
        while mainloop_active
            mainloop_iteration(app)
            yield()
            GLFW.WaitEvents(quantum)
        end
    end

    quantum = get_quantum(refresh)
    refresh_task = Task(() -> refresh_func(app, quantum))
    mainloop_task = Task(() -> mainloop_func(app, quantum))

    schedule(refresh_task)
    schedule(mainloop_task)

    iszero(Base.JLOptions().isinteractive) && wait(closenotify)
    (mainloop_task, refresh_task)
end
