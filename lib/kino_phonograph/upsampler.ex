defmodule KinoPhonograph.Upsampler do
  def upsample_linear(x, target_points) do
    {c, n} = Nx.shape(x)

    pos =
      Nx.linspace(0.0, Nx.subtract(n, 1), n: target_points)
      |> Nx.reshape({1, target_points})
      |> Nx.broadcast({c, target_points})

    i0 =
      pos
      |> Nx.floor()
      |> Nx.as_type(:s64)

    i1 =
      Nx.min(
        Nx.add(i0, 1),
        Nx.broadcast(n |> Nx.subtract(1), {c, target_points})
      )

    x_exp =
      Nx.new_axis(x, 1)

    y0 =
      Nx.take_along_axis(
        x_exp,
        Nx.new_axis(i0, 0),
        axis: 2
      )
      |> Nx.squeeze(axes: [1])

    y1 =
      Nx.take_along_axis(
        x_exp,
        Nx.new_axis(i1, 0),
        axis: 2
      )
      |> Nx.squeeze(axes: [1])

    frac =
      Nx.subtract(
        pos,
        Nx.as_type(i0, Nx.type(pos))
      )

    Nx.add(
      y0,
      Nx.multiply(
        frac,
        Nx.subtract(y1, y0)
      )
    )
  end
end
