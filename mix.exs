defmodule Sublocator.MixProject do
  use Mix.Project

  def project do
    [
      app: :sublocator,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      name: "Sublocator",
      source_url: "https://github.com/westonlit/sublocator",
      docs: [
        main: "Sublocator"
      ],
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
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
      {:excoveralls, "~> 0.10", only: :test},
      {:ex_doc, "~> 0.19", only: [:dev, :test], runtime: false}
    ]
  end

  defp description do
    "Identify line and column location(s) of a pattern in a given string."
  end

  defp package do
    [
      name: "sublocator",
      maintainers: ["Weston Littrell"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/westonlit/sublocator"}
    ]
  end
end
