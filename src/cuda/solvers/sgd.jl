function update_parameters(net::Net{CuDNNBackend}, solver::SGD, learning_rate, momentum, state, param_blob, hist_blob, gradient, data_type)
  # hist_blob = net.sys.momentum * hist_blob
  CuBLAS.scal(net.sys.backend.cublas_ctx, length(hist_blob), convert(data_type, momentum),
      hist_blob.ptr, 1)
  # hist_blob = learning_rate * gradient + hist_blob
  CuBLAS.axpy(net.sys.backend.cublas_ctx, length(hist_blob), convert(data_type, learning_rate),
      gradient.ptr, 1, hist_blob.ptr, 1)

  # update parameter
  # param_blob = param_blob - hist_blob
  CuBLAS.axpy(net.sys.backend.cublas_ctx, length(hist_blob), convert(data_type, -1),
      hist_blob.ptr, 1, param_blob.ptr, 1)
end

