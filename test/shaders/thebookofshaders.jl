module test_shaders_thebookofshaders

# https://thebookofshaders.com

using Test
using StaticArrays

const vec2 = SVector{2}
const vec3 = SVector{3}
const vec4 = SVector{4}

function Base.floor(v::SVector{N}) where N
    SVector{N}(floor.(v))
end

function fract(v::SVector{N}) where N
    v .- floor.(v)
end

function vec4(v::vec3, a)
    vec4(v..., a)
end

function vec4(a, v::vec2, b)
    vec4(a, v..., b)
end

function vec4(v::vec2, a, b)
    vec4(v..., a, b)
end

function vec3(v::vec4)
    vec3(v[1:3])
end

@test vec2(1.5, 2.6) isa SArray{Tuple{2},Float64,1,2}
@test floor(vec2(1.5, 2.6)) == vec2(1.0, 2.0)

@test floor(vec2(1.5, 2.6)) == vec2(1.0, 2.0)
@test fract(vec2(1.5, 2.6)) ≈  vec2(0.5, 0.6)
@test vec4(vec3(1.0, 0.0, 1.0), 1.0) == vec4(1.0, 0.0, 1.0, 1.0)
@test vec3(vec4(1.0, 2.0, 3.0, 4.0)) == vec3(1.0, 2.0, 3.0)
@test vec4(vec2(10.0, 11.0), 1.0, 3.5) == vec4(10.0, vec2(11.0, 1.0), 3.5)

end # module test_shaders_thebookofshaders
