defmodule Copper.MixProject do
  use Mix.Project

  def project do
    [
      app: :copper,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:credo, "~> 0.9", only: :dev, runtime: false},
      {:ex_doc, "~> 0.21", only: :dev, runtime: false},
      {:dummy, "~> 1.2", only: :test},
      {:jason, "~> 1.1"},
      {:plug, "~> 1.8"},
      {:plug_cowboy, "~> 2.1"}
    ]
  end
end
