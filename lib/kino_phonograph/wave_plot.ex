defmodule KinoPhonograph.WavePlot do
  @moduledoc """
  Documentation for `KinoPhonograph.WavePlot`.
  """

  def plot(audios, args \\ [])

  def plot(audio, args) when not is_list(audio) do
    plot([audio], args)
  end

  def plot(audios = [_ | _], args) do
    width = Keyword.get(args, :width, 512)
    height = Keyword.get(args, :height, 100)
    padding = Keyword.get(args, :padding, 14)
    labels = Keyword.get(args, :labels, [])
    titel = Keyword.get(args, :titel, "Waveforms")
    bg_color = Keyword.get(args, :background, {1, 1, 1, 1}) |> Tuple.to_list()
    fg_color = Keyword.get(args, :foreground, {0, 0, 0, 1}) |> Tuple.to_list()
    debug = Keyword.get(args, :debug, false)
    ranges = Keyword.get(args, :ranges, [])

    for {audio, ai} <- audios |> Enum.with_index() do
      length = Nx.axis_size(audio, 1)
      {range_start, range_end, range_color} = ranges |> Enum.at(ai, {0, 0, {0, 0, 0, 0}})

      {min, max} =
        if length / 2 > width do
          audio
        else
          audio |> KinoPhonograph.Upsampler.upsample_linear(width * 8)
        end
        |> KinoPhonograph.Downsampler.downsample_minmax(width)

      scale = width / length

      min_left = roll(min, 1, 0)
      min_right = roll(min, -1, 0)

      max_left = roll(min, 1, 0)
      max_right = roll(min, -1, 0)

      res =
        Nx.subtract(Nx.reduce_max(audio), Nx.reduce_min(audio))
        |> Nx.divide(height)
        |> Nx.divide(2)

      mmin =
        min
        |> Nx.min(max |> Nx.subtract(res))
        |> Nx.min(Nx.add(min_left, max_left) |> Nx.multiply(0.5))
        |> Nx.min(Nx.add(min_right, max_right) |> Nx.multiply(0.5))

      mmax =
        max
        |> Nx.max(min |> Nx.add(res))
        |> Nx.max(Nx.add(min_left, max_left) |> Nx.multiply(0.5))
        |> Nx.max(Nx.add(min_right, max_right) |> Nx.multiply(0.5))

      grid =
        Nx.concatenate([
          Nx.iota({height + padding, 1})
          |> Nx.divide(height)
          |> Nx.reverse(axes: [0])
          |> Nx.multiply(Nx.reduce_max(max)),
          Nx.iota({height + padding, 1})
          |> Nx.divide(height)
          |> Nx.multiply(Nx.reduce_min(min))
        ])
        |> Nx.multiply(Nx.broadcast(1, Nx.shape(min)))

      wave =
        Nx.logical_and(
          grid
          |> Nx.greater_equal(mmin),
          grid
          |> Nx.less_equal(mmax)
        )
        |> Nx.new_axis(0)
        |> Nx.new_axis(-1)

      time =
        Nx.iota({Nx.axis_size(wave, 2)})

      marked =
        Nx.tensor(
          range_color
          |> Tuple.to_list()
        )
        |> Nx.new_axis(0)
        |> Nx.new_axis(0)
        |> Nx.new_axis(0)
        |> Nx.multiply(
          Nx.logical_and(
            time |> Nx.less_equal(range_end * scale),
            time |> Nx.greater_equal(range_start * scale)
          )
          |> Nx.new_axis(-1)
          |> Nx.new_axis(0)
        )

      fg =
        Nx.tensor(fg_color)
        |> Nx.new_axis(0)
        |> Nx.new_axis(0)
        |> Nx.new_axis(0)
        |> Nx.multiply(wave)

      bg =
        Nx.tensor(bg_color)
        |> Nx.new_axis(0)
        |> Nx.new_axis(0)
        |> Nx.new_axis(0)
        |> Nx.add(marked)
        |> Nx.multiply(Nx.subtract(1, wave))

      Nx.add(fg, bg)
      |> Nx.multiply(255)
    end
    |> KinoZoetrope.TensorStack.new(
      size: width,
      legend: debug,
      show_meta: debug,
      labels: labels,
      titel: titel
    )
  end

  defp roll(nx, shift, axis) do
    n = Nx.axis_size(nx, axis)

    shift =
      rem(
        shift + n,
        n
      )

    left =
      Nx.slice_along_axis(nx, 0, n - shift, axis: axis)

    right =
      Nx.slice_along_axis(nx, n - shift, shift, axis: axis)

    Nx.concatenate([right, left], axis: axis)
  end
end
