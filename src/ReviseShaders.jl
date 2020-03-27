module ReviseShaders # Shaders

using Revise: Revise, PkgData, revise, maybe_parse_from_cache!, basedir, file_exists, parse_source, ModuleExprsSigs, delete_missing!, eval_new!, unwrap
using MacroTools

_targets = Dict{String,Set{Type}}()

function track(T::Type, file)
    if haskey(_targets, file)
        push!(_targets[file], T)
    else
        _targets[file] = Set{Type}([T])
    end
    isfile(file) && Revise.track(file)
end

function Revise.handle_deletions(pkgdata::PkgData, file)
    fi = maybe_parse_from_cache!(pkgdata, file)
    mexsold = fi.modexsigs
    filep = normpath(joinpath(basedir(pkgdata), file))
    topmod = first(keys(mexsold))
    mexsnew = file_exists(filep) ? parse_source(filep, topmod) :
              (@warn("$filep no longer exists, deleting all methods"); ModuleExprsSigs(topmod))
    if mexsnew !== nothing
        # println.(stacktrace());
        delete_missing!(mexsold, mexsnew)
        if haskey(_targets, file)
            typeset = _targets[file]
            try
                for (mod, exsigs) in fi.modexsigs
                    for def in keys(exsigs)
                        ex = Base.remove_linenums!(def.ex)
                        exuw = unwrap(ex)
                        for T in typeset
                            typename = Symbol(T)
                            if @capture(exuw, (function $typename(ctx_) body_ end))
                                @info :capture_w body
                            elseif @capture(exuw, (function render(_::$typename, time_, frametime_) body_ end))
                                @info :capture_render body
                            end
                        end
                    end
                end
            catch err
                @info :err err
            end
        end
    end
    return mexsnew, mexsold
end

end # module Shaders.ReviseShaders
