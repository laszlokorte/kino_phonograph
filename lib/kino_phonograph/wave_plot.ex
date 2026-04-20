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
    padding = Keyword.get(args, :padding, 10)
    labels = Keyword.get(args, :labels, [])
    titel = Keyword.get(args, :titel, "Waveforms")
    bg_color = Keyword.get(args, :background, {1, 1, 1, 1}) |> Tuple.to_list()
    fg_color = Keyword.get(args, :foreground, {0, 0, 0, 1}) |> Tuple.to_list()
    debug = Keyword.get(args, :debug, false)
    ranges = Keyword.get(args, :ranges, [])

    for {audio, ai} <- audios |> Enum.with_index() do
      audio = Nx.vectorize(audio, :channel)
      length = Nx.axis_size(audio, 0)
      {range_start, range_end, range_color} = ranges |> Enum.at(ai, {0, 0, {0, 0, 0, 0}})

      vmin = Keyword.get(args, :vmin, Nx.reduce_min(audio))
      vmax = Keyword.get(args, :vmax, Nx.reduce_max(audio)) |> Nx.subtract(vmin)

      audio =
        audio
        |> then(&Nx.subtract(&1, vmin))
        |> then(&Nx.divide(&1, vmax))
        |> Nx.subtract(0.5)
        |> Nx.multiply(2)

      {min, max} =
        if length / 2 > width do
          audio
        else
          audio |> KinoPhonograph.Upsampler.upsample_linear(width * 8)
        end
        |> KinoPhonograph.Downsampler.downsample_minmax(width + 2)

      scale = width / length

      min_left = roll(min, 1, 0)
      min_right = roll(min, -1, 0)

      max_left = roll(min, 1, 0)
      max_right = roll(min, -1, 0)

      ampl =
        Nx.reduce_max(Nx.abs(audio))
        |> Nx.max(1)
        |> Nx.divide(height)

      mmin =
        min
        |> Nx.min(max |> Nx.subtract(ampl))
        |> Nx.min(Nx.add(min_left, max_left) |> Nx.multiply(0.5))
        |> Nx.min(Nx.add(min_right, max_right) |> Nx.multiply(0.5))

      mmax =
        max
        |> Nx.max(min |> Nx.add(ampl))
        |> Nx.max(Nx.add(min_left, max_left) |> Nx.multiply(0.5))
        |> Nx.max(Nx.add(min_right, max_right) |> Nx.multiply(0.5))

      grid =
        Nx.concatenate([
          Nx.iota({height * 2 + padding * 2, 1})
          |> Nx.subtract(height)
          |> Nx.add(0.5)
          |> Nx.subtract(padding)
          |> Nx.reverse(axes: [0])
          |> Nx.multiply(ampl)
        ])
        |> Nx.multiply(Nx.broadcast(1, Nx.shape(min)))

      wave =
        Nx.logical_and(
          grid
          |> Nx.greater_equal(mmin),
          grid
          |> Nx.less_equal(mmax)
        )
        |> Nx.slice_along_axis(1, width, axis: 1)
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
        |> Nx.multiply(wave)

      bg =
        Nx.tensor(bg_color)
        |> Nx.new_axis(0)
        |> Nx.new_axis(0)
        |> Nx.add(marked)
        |> Nx.multiply(Nx.subtract(1, wave))

      if debug do
        grid
        |> Nx.slice_along_axis(1, width, axis: 1)
        |> Nx.new_axis(-1)
      else
        Nx.add(fg, bg)
        |> Nx.multiply(255)
      end
    end
    |> Nx.new_axis(0)
    |> KinoZoetrope.TensorStack.new(
      [
        size: width,
        legend: debug,
        show_meta: debug,
        labels: labels,
        titel: titel,
        sharp: false
      ]
      |> Keyword.merge(args)
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
