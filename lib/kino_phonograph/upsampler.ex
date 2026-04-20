defmodule KinoPhonograph.Upsampler do
  def upsample_linear(x, target_points) do
    {n} = Nx.shape(x)

    pos =
      Nx.linspace(0.0, Nx.subtract(n, 1), n: target_points)
      |> Nx.reshape({target_points})
      |> Nx.broadcast({target_points})

    i0 = pos |> Nx.floor() |> Nx.as_type(:s64)

    i1 = Nx.min(Nx.add(i0, 1), Nx.broadcast(n |> Nx.subtract(1), {target_points}))

    x_exp = Nx.new_axis(x, 0)

    y0 =
      Nx.take_along_axis(
        x_exp,
        Nx.new_axis(i0, 0),
        axis: 1
      )
      |> Nx.squeeze(axes: [0])

    y1 =
      Nx.take_along_axis(
        x_exp,
        Nx.new_axis(i1, 0),
        axis: 1
      )
      |> Nx.squeeze(axes: [0])

    frac = Nx.subtract(pos, Nx.as_type(i0, Nx.type(pos)))

    Nx.add(y0, Nx.multiply(frac, Nx.subtract(y1, y0)))
  end
end
