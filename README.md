# KinoPhonograph

![Result Rendered in Livebook](./phonograph.gif)

KinoPhonograph is a helper module for rendering 1D and 2D `Nx.Tensor` audio signals as wave forms in [Livebook](https://livebook.dev/).

## Installation

[![kino_phonograph](https://img.shields.io/hexpm/v/kino_phonograph)](https://hex.pm/packages/kino_phonograph)

In Livebook add `kino_phonograph` to your dependencies:

```elixir
Mix.install([
  {:nx, "~> 0.10.0"},
  {:kino, "~> 0.20.0"},
  {:image, "~> 0.62.1"},
  # add this:
  {:kino_phonograph, "~> 0.1.0"}
])
```

## Example

[![Run in Livebook](https://livebook.dev/badge/v1/blue.svg)](https://livebook.dev/run?url=https%3A%2F%2Fgithub.com%2Flaszlokorte%2Fkino_phonograph%2Fblob%2Fmain%2Fguides%2Fexample.livemd)
