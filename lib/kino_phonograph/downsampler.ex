defmodule KinoPhonograph.Downsampler do
  def downsample_minmax(x, target_points) do
    n = Nx.axis_size(x, 1)
    chunk = max(div(n, target_points), 1)

    trimmed = Nx.slice_along_axis(x, 0, div(n, chunk) * chunk, axis: 1)

    reshaped =
      trimmed
      |> Nx.reshape({:auto, chunk})

    mins = Nx.reduce_min(reshaped, axes: [1])
    maxs = Nx.reduce_max(reshaped, axes: [1])

    {mins, maxs}
  end
end
