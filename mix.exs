defmodule KinoPhonograph.MixProject do
  use Mix.Project

  def project do
    [
      app: :kino_phonograph,
      version: "0.7.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      source_url: "https://github.com/laszlokorte/kino_phonograph",
      package: package()
    ]
  end

  defp package() do
    %{
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/laszlokorte/kino_phonograph"}
    }
  end

  defp description() do
    "Helper for plotting 1D Nx tensors as waveform"
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:nx, "~> 0.11.0"},
      {:kino, "~> 0.19.0"},
      {:image, "~> 0.62.1"},
      {:kino_zoetrope, "~> 0.23.0"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end
end
