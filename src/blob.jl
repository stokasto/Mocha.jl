export Blob
export CPUBlob, NullBlob

import Base: eltype, size, length, copy!, fill!
export       eltype, size, length, copy!, fill!, erase!
export get_num, get_chann, get_height, get_width
export make_blob, make_zero_blob, make_shared_blob

############################################################
# A blob is an abstract concept that is suppose
# to hold a 4-D tensor of data. The data could
# either live in CPU memory or GPU memory or
# whatever the backend is used to store the data.
############################################################
abstract Blob

############################################################
# The following should be implemented for a
# concrete Blob type. Note the following
# procedures are only provided for convenience
# and mainly for components that do not need
# to know the underlying backend (e.g. Filler).
############################################################
function eltype(blob :: Blob)
  error("Not implemented (should return the element type)")
end

function size(blob :: Blob)
  error("Not implemented (should return the size of data)")
end
function destroy(blob :: Blob)
  error("Not implemented (should destroy the blob)")
end
function size(blob :: Blob, dim :: Int)
  size(blob)[dim]
end
function length(blob :: Blob)
  return prod(size(blob))
end

function get_num(blob :: Blob)
  size(blob, 4)
end
function get_chann(blob :: Blob)
  size(blob, 3)
end
function get_height(blob :: Blob)
  size(blob, 2)
end
function get_width(blob :: Blob)
  size(blob, 1)
end


function copy!(dst :: Array, src :: Blob)
  error("Not implemented (should copy content of src to dst)")
end
function copy!(dst :: Blob, src :: Array)
  error("Not implemented (should copy content of src to dst)")
end
function fill!(dst :: Blob, val)
  error("Not implemented (should fill dst with val)")
end
function erase!(dst :: Blob)
  fill!(dst, 0)
end

# Get canonical 4D tensor dims
# Note we store data in column-major order, thus
# the data shape is width, height, channel, num
function blob_canonical_dims(dims...)
  if length(dims) == 1 && isa(dims[1], NTuple)
    dims = dims[1]
  end

  if length(dims) > 4
    error("Tensor dimension ($(length(dims))) twoo high, only 4D tensor supported")
  end
  if length(dims) < 4
    # add singleton dimensions
    dims = tuple(dims..., ones(Int, 4-length(dims))...)
    error("In order to avoid potential bugs, now we require specifying the 4 dimensions explicitly")
  end
  return dims
end

############################################################
# A Dummy Blob type holding nothing
############################################################
type NullBlob <: Blob
end
function fill!(dst :: NullBlob, val)
  # do nothing
end

function destroy(blob::NullBlob)
  # do nothing
end
function make_blob()
  return NullBlob()
end
function make_blob(backend::Backend, data_type::Type, dims...)
  error("Not implemented (should return a blob for corresponding backend)")
end
function make_blob(backend::Backend, data::Array)
  blob = make_blob(backend, eltype(data), size(data))
  copy!(blob, data)
  return blob
end
function make_zero_blob(backend::Backend, data_type::Type, dims...)
  blob = make_blob(backend, data_type, dims...)
  erase!(blob)
  return blob
end

function make_shared_blob(backend::Backend, blob::Blob, dims...)
  error("Not implemented (should make a blob that share data)")
end

############################################################
# A Blob for CPU Computation
############################################################
immutable CPUBlob{T <: FloatingPoint} <: Blob
  data :: Array{T, 4}
end
CPUBlob(t :: Type, dims :: NTuple{Int}) = CPUBlob(Array(t, blob_canonical_dims(dims...)))
CPUBlob(t :: Type, dims...) = CPUBlob(t, dims)

function make_blob(backend::CPUBackend, data_type::Type, dims...)
  return CPUBlob(data_type, dims...)
end
function make_shared_blob{T}(backend::CPUBackend, blob::CPUBlob{T}, dims...)
  dims = blob_canonical_dims(dims...)
  @assert prod(dims) == length(blob)
  return CPUBlob{T}(reshape(blob.data, dims))
end
function destroy(blob::CPUBlob)
  # do nothing... or is there anything that I could do?
end

eltype{T}(::CPUBlob{T}) = T
size(blob::CPUBlob) = size(blob.data)

function copy!{T}(dst :: Array{T}, src :: CPUBlob{T})
  @assert length(dst) == length(src)
  dst[:] = src.data[:]
end
function copy!{T}(dst :: CPUBlob{T}, src :: Array{T})
  @assert length(dst) == length(src)
  dst.data[:] = src[:]
end
function copy!{T}(dst :: CPUBlob{T}, src :: CPUBlob{T})
  dst.data[:] = src.data[:]
end
function fill!{T}(dst :: CPUBlob{T}, src)
  fill!(dst.data, src)
end
