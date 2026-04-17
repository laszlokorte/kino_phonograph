defmodule KinoPhonograph.Player do
  @moduledoc """
  Documentation for `KinoPhonograph.TensorStack`.
  """
  use Kino.JS, entrypoint: "audio.js", assets_path: "lib/assets"

  def new(tensors, args \\ [])

  def new(tensor = %Nx.Tensor{}, args) do
    new([tensor], args)
  end

  def new(tensors, args) when is_list(tensors) do
    tracks =
      for {t, ti} <- tensors |> Enum.with_index() do
        normalized =
          if(Keyword.get(args, :normalize, true)) do
            t |> then(&Nx.divide(&1, Nx.reduce_max(Nx.abs(&1))))
          else
            t
          end

        %{
          samples: Nx.to_list(normalized),
          label:
            case args |> Keyword.get(:label, []) do
              l when is_list(l) -> Enum.at(l, ti, "Track #{ti + 1}")
              l when is_binary(l) -> l
              _ -> nil
            end,
          loop:
            case args |> Keyword.get(:loop, []) do
              l when is_list(l) -> Enum.at(l, ti, false)
              l when is_boolean(l) -> l
              _ -> nil
            end
            |> case do
              true -> true
              _ -> false
            end,
          sample_rate:
            case args |> Keyword.get(:sample_rate, []) do
              s when is_list(s) -> Enum.at(s, ti, 16000)
              s when is_number(s) -> s
              _ -> raise ":sample_rate must be a number or list of numbers"
            end
        }
      end

    Kino.JS.new(__MODULE__, %{
      tracks: tracks,
      titel: Keyword.get(args, :titel, "Audios"),
      show_meta: args |> Keyword.get(:show_meta, true),
      sample_rate: Keyword.get(args, :sample_rate)
    })
  end
end
