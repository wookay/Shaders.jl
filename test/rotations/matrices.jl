module test_rotations_matrices

using Test
using LinearAlgebra
#=
using Rotations

# https://learnopengl.com/Getting-started/Transformations
@test [1 2; 3 4] + [5 6; 7 8] == [6 8; 10 12]
@test [4 2; 1 6] - [2 4; 0 1] == [2 -2; 1 5]
@test [4 2 0; 0 8 1; 0 1 0] * [4 2 1; 2 0 4; 9 4 2] == [20 8 12; 25 4 34; 2 0 4]
@test [1 0 0 0; 0 1 0 0; 0 0 1 0; 0 0 0 1] * [1;2;3;4] == I * [1;2;3;4] == [1;2;3;4]

s1, s2, s3 = 1, 2, 3
x,  y,  z  = 4, 5, 6
@test diagm([s1, s2, s3, 1]) * [x; y; z; 1] == [s1 * x; s2 * y; s3 * z; 1]

tx, ty, tz = 7, 8, 9
@test [1 0 0 tx; 0 1 0 ty; 0 0 1 tz; 0 0 0 1] * [x; y; z; 1] == [x + tx; y + ty; z + tz; 1]

θ = deg2rad(45)
@test [1 0 0 0; 0 cos(θ) -sin(θ) 0; 0 sin(θ) cos(θ) 0; 0 0 0 1] * [x; y; z; 1] == [x; cos(θ) * y - sin(θ) * z; sin(θ) * y + cos(θ) * z; 1]
@test RotX(θ) * [x; y; z] == [x; cos(θ) * y - sin(θ) * z; sin(θ) * y + cos(θ) * z]
@test RotY(θ) * [x; y; z] == [cos(θ) * x + sin(θ) * z; y; -sin(θ) * x + cos(θ) * z]
@test RotZ(θ) * [x; y; z] == [cos(θ) * x - sin(θ) * y; sin(θ) * x + cos(θ) * y; z]
=#

using StaticArrays
const Vector3f = SVector{3, Cfloat}
const Matrix4f = MMatrix{4, 4, Cfloat}

function look_at(origin::Vector3f, target::Vector3f, up::Vector3f)::Matrix4f
    f = normalize(target - origin)
    s = normalize(cross(f, up))
    u = cross(s, f)
    Matrix4f([
        s[1] u[1] -f[1] 0
        s[2] u[2] -f[2] 0
        s[3] u[3] -f[3] 0
        -dot(s, origin) -dot(u, origin) dot(f, origin) 1
    ]) 
end

# enoki::rotate
function rotate(axis::Vector3f, angle::Cfloat)::Matrix4f
    s, c = sincos(angle)
    cm = 1 - c
    shuf1 = Vector3f(getindex.(Ref(axis), (2, 3, 1)))
    shuf2 = Vector3f(getindex.(Ref(axis), (3, 1, 2)))
    tmp0 = axis .* axis .* cm .+ c
    tmp1 = axis .* shuf1 .* cm .+ shuf2 .* s
    tmp2 = axis .* shuf2 .* cm .- shuf1 .* s
    Matrix4f([
        tmp0[1] tmp1[1] tmp2[1] 0
        tmp2[2] tmp0[2] tmp1[2] 0
        tmp1[3] tmp2[3] tmp0[3] 0
        0 0 0 1
    ])
end

# enoki::perspective
function perspective(fov::Cfloat, near::Cfloat, far::Cfloat, aspect::Cfloat)::Matrix4f
    recip = 1 / (near - far)
    c = cot(0.5 * fov)
    Matrix4f([
        c / aspect 0 0                       0
        0          c 0                       0
        0          0 (near + far) * recip   -1
        0          0 2 * near * far * recip  0
    ])
end

function f(t::Cfloat, rot::Cfloat)
    #t = Cfloat(glfwGetTime())
    #rot = Cfloat(0)
    view = look_at(Vector3f(0, -2, -10), Vector3f(0, 0, 0), Vector3f(0, 1, 0))
    #@info :view view
    model = rotate(Vector3f(0, 1, 0), t)
    #@info :model model
    model2 = rotate(Vector3f(1, 0, 0), rot)
    # @info :model2 model2
    proj = perspective(Cfloat(25 * pi / 180), Cfloat(0.1), Cfloat(20), Cfloat(1))
    #@info :proj proj
end

f(Cfloat(0), Cfloat(0))
f(Cfloat(0.1), Cfloat(0))

#=
axis = Vector3f(0, 1, 0)
rotate(axis, Cfloat(0.5))

axis = Vector3f(1, 0, 0)
rotate(axis, Cfloat(0.5))

cameraPos = Vector3f(0.0, 0.0,  3.0)
cameraFront = Vector3f(0.0, 0.0, -1.0)
cameraUp = Vector3f(0.0, 1.0,  0.0)
j = look_at(cameraPos, cameraPos + cameraFront, cameraUp)
@info :j j
=#

#perspective(Cfloat(25 * pi / 180), Cfloat(0.1), Cfloat(20), Cfloat(1))

# rotate<Matrix4f>( Vector3f(0, 1, 0), t //(float) glfwGetTime());
# model = {{1, 0, 0, 0}, {0, 1, 0, 0}, {0, 0, 1, 0}, {0, 0, 0, 1}} (enoki::Matrix<float, 4>)
# rotate<Matrix4f>( Vector3f(1, 0, 0), rot // m_rotation);
# model2 = {{1, 0, 0, 0}, {0, 1, 0, 0}, {0, 0, 1, 0}, {0, 0, 0, 1}} (enoki::Matrix<float, 4>)

# R is the right vector
# U is the up vector
# D is the direction vector
# P is the camera's position vector

# cameraPos   0.0, 0.0,  3.0
# cameraFront 0.0, 0.0, -1.0
# cameraUp    0.0, 1.0,  0.0
# lookAt(cameraPos, cameraPos + cameraFront, cameraUp)

end # module test_rotations_matrices
