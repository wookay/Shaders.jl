module test_moderngl_api

using ModernGL

### VBO - Vertex Buffer Objects

    # https://www.khronos.org/registry/OpenGL-Refpages/gl4/html/glGenBuffers.xhtml
"""
    void glGenBuffers(GLsizei n, GLuint * buffers);

n
Specifies the number of buffer object names to be generated.

buffers
Specifies an array in which the generated buffer object names are stored.
"""
glGenBuffers

"""
    void glBindBuffer(GLenum target, GLuint buffer);

target
Specifies the target to which the buffer object is bound, which must be one of the buffer binding targets in the following table:

    GL_ARRAY_BUFFER	Vertex attributes
    GL_ATOMIC_COUNTER_BUFFER	Atomic counter storage
    GL_COPY_READ_BUFFER	Buffer copy source
    GL_COPY_WRITE_BUFFER	Buffer copy destination
    GL_DISPATCH_INDIRECT_BUFFER	Indirect compute dispatch commands
    GL_DRAW_INDIRECT_BUFFER	Indirect command arguments
    GL_ELEMENT_ARRAY_BUFFER	Vertex array indices
    GL_PIXEL_PACK_BUFFER	Pixel read target
    GL_PIXEL_UNPACK_BUFFER	Texture data source
    GL_QUERY_BUFFER	Query result buffer
    GL_SHADER_STORAGE_BUFFER	Read-write storage for shaders
    GL_TEXTURE_BUFFER	Texture data buffer
    GL_TRANSFORM_FEEDBACK_BUFFER	Transform feedback buffer
    GL_UNIFORM_BUFFER	Uniform block storage

buffer
Specifies the name of a buffer object.
"""
glBindBuffer

"""
    void glBufferData(GLenum target, GLsizeiptr size, const void * data, GLenum usage);

target
Specifies the target to which the buffer object is bound for glBufferData, which must be one of the buffer binding targets in the following table:

buffer
Specifies the name of the buffer object for glNamedBufferData function.

size
Specifies the size in bytes of the buffer object's new data store.

data
Specifies a pointer to data that will be copied into the data store for initialization, or NULL if no data is to be copied.

usage
Specifies the expected usage pattern of the data store. The symbolic constant must be GL_STREAM_DRAW, GL_STREAM_READ, GL_STREAM_COPY, GL_STATIC_DRAW, GL_STATIC_READ, GL_STATIC_COPY, GL_DYNAMIC_DRAW, GL_DYNAMIC_READ, or GL_DYNAMIC_COPY.
"""
glBufferData


### VAO - Vertex Array Objects
"""
    void glGenVertexArrays(GLsizei n, GLuint *arrays);

n
Specifies the number of vertex array object names to generate.

arrays
Specifies an array in which the generated vertex array object names are stored.
"""
glGenVertexArrays

"""
    void glBindVertexArray(GLuint array);

array
Specifies the name of the vertex array to bind.
"""
glBindVertexArray

glBindBuffer
glBufferData

    # https://www.khronos.org/registry/OpenGL-Refpages/gl4/html/glVertexAttribPointer.xhtml
"""
    void glVertexAttribPointer(GLuint index, GLint size, GLenum type, GLboolean normalized, GLsizei stride, const void * pointer);

index
Specifies the index of the generic vertex attribute to be modified.

size
Specifies the number of components per generic vertex attribute. Must be 1, 2, 3, 4. Additionally, the symbolic constant GL_BGRA is accepted by glVertexAttribPointer. The initial value is 4.

type
Specifies the data type of each component in the array. The symbolic constants GL_BYTE, GL_UNSIGNED_BYTE, GL_SHORT, GL_UNSIGNED_SHORT, GL_INT, and GL_UNSIGNED_INT are accepted by glVertexAttribPointer and glVertexAttribIPointer. Additionally GL_HALF_FLOAT, GL_FLOAT, GL_DOUBLE, GL_FIXED, GL_INT_2_10_10_10_REV, GL_UNSIGNED_INT_2_10_10_10_REV and GL_UNSIGNED_INT_10F_11F_11F_REV are accepted by glVertexAttribPointer. GL_DOUBLE is also accepted by glVertexAttribLPointer and is the only token accepted by the type parameter for that function. The initial value is GL_FLOAT.

normalized
For glVertexAttribPointer, specifies whether fixed-point data values should be normalized (GL_TRUE) or converted directly as fixed-point values (GL_FALSE) when they are accessed.

stride
Specifies the byte offset between consecutive generic vertex attributes. If stride is 0, the generic vertex attributes are understood to be tightly packed in the array. The initial value is 0.

pointer
Specifies a offset of the first component of the first generic vertex attribute in the array in the data store of the buffer currently bound to the GL_ARRAY_BUFFER target. The initial value is 0.

"""
glVertexAttribPointer

"""
    void glEnableVertexAttribArray(GLuint index);

vaobj
Specifies the name of the vertex array object for glDisableVertexArrayAttrib and glEnableVertexArrayAttrib functions.

index
Specifies the index of the generic vertex attribute to be enabled or disabled.
"""
glEnableVertexAttribArray

"""
    void glDrawArrays(GLenum mode, GLint first, GLsizei count);

mode
Specifies what kind of primitives to render. Symbolic constants GL_POINTS, GL_LINE_STRIP, GL_LINE_LOOP, GL_LINES, GL_LINE_STRIP_ADJACENCY, GL_LINES_ADJACENCY, GL_TRIANGLE_STRIP, GL_TRIANGLE_FAN, GL_TRIANGLES, GL_TRIANGLE_STRIP_ADJACENCY, GL_TRIANGLES_ADJACENCY and GL_PATCHES are accepted.

first
Specifies the starting index in the enabled arrays.

count
Specifies the number of indices to be rendered.
"""
glDrawArrays

### EBO - Element Buffer Objects
glBindBuffer
glBufferData

"""
    void glDrawElements(GLenum mode, GLsizei count, GLenum type, const void * indices);

mode
Specifies what kind of primitives to render. Symbolic constants GL_POINTS, GL_LINE_STRIP, GL_LINE_LOOP, GL_LINES, GL_LINE_STRIP_ADJACENCY, GL_LINES_ADJACENCY, GL_TRIANGLE_STRIP, GL_TRIANGLE_FAN, GL_TRIANGLES, GL_TRIANGLE_STRIP_ADJACENCY, GL_TRIANGLES_ADJACENCY and GL_PATCHES are accepted.

count
Specifies the number of elements to be rendered.

type
Specifies the type of the values in indices. Must be one of GL_UNSIGNED_BYTE, GL_UNSIGNED_SHORT, or GL_UNSIGNED_INT.

indices
Specifies a pointer to the location where the indices are stored.
"""
glDrawElements


"""
    void glShaderSource(GLuint shader, GLsizei count, const GLchar **string, const GLint *length);

shader
Specifies the handle of the shader object whose source code is to be replaced.

count
Specifies the number of elements in the string and length arrays.

string
Specifies an array of pointers to strings containing the source code to be loaded into the shader.

length
Specifies an array of string lengths.
"""
glShaderSource

"""
    void glMatrixMode(GLenum mode);

mode
Specifies which matrix stack is the target for subsequent matrix operations. These values are accepted: GL_MODELVIEW, GL_PROJECTION, and GL_TEXTURE. The initial value is GL_MODELVIEW.

	GL_MODELVIEW Applies subsequent matrix operations to the modelview matrix stack.
    GL_PROJECTION Applies subsequent matrix operations to the projection matrix stack.
    GL_TEXTURE Applies subsequent matrix operations to the texture matrix stack.
"""
glMatrixMode


glGenBuffers

"""
    void glGenFramebuffers(GLsizei n, GLuint *ids);

n
Specifies the number of framebuffer object names to generate.

ids
Specifies an array in which the generated framebuffer object names are stored.
"""
glGenFrameBuffers

"""
    void glGenRenderbuffers(GLsizei n, GLuint * renderbuffers);

n
Specifies the number of renderbuffer object names to generate.

renderbuffers
Specifies an array in which the generated renderbuffer object names are stored.
"""
glGenRenderbuffers

"""
in int gl_VertexID;

gl_VertexID is a vertex language input variable that holds an integer index for the vertex. The index is implicitly generated by glDrawArrays and other commands that do not reference the content of the GL_ELEMENT_ARRAY_BUFFER, or explicitly generated from the content of the GL_ELEMENT_ARRAY_BUFFER by commands such as glDrawElements. For glDrawElements forms that take a basevertex, gl_VertexID will have this value added to the index from the buffer.
"""
# gl_VertexID

"""
    void glGetActiveUniformBlockName(GLuint program, GLuint uniformBlockIndex, GLsizei bufSize, GLsizei *length, GLchar *uniformBlockName);

program
Specifies the name of a program containing the uniform block.

uniformBlockIndex
Specifies the index of the uniform block within program.

bufSize
Specifies the size of the buffer addressed by uniformBlockName.

length
Specifies the address of a variable to receive the number of characters that were written to uniformBlockName.

uniformBlockName
Specifies the address an array of characters to receive the name of the uniform block at uniformBlockIndex.
"""
glGetActiveUniformBlockName

glGetActiveUniformBlockiv

glGetUniformBlockIndex

end # module test_moderngl_api
