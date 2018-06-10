defmodule Sublocator.MixProject do
  use Mix.Project

  def project do
    [
      app: :sublocator,
      version: "0.1.0",
      elixir: "~> 1.6",
      elixirc_paths: ["./", "lib"],
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      name: "nameparts",
      source_url: "https://github.com/bhdirect-ebooks/sublocator",
      docs: [
        extras: ["README.md"],
        main: "readme",
        filter_prefix: "Sublocator"
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
      {:excoveralls, "~> 0.9", only: :test},
      {:ex_doc, "~> 0.18", only: :dev, runtime: false}
    ]
  end

  defp description do
    "Returns line and column location(s) of a substring or Regex pattern in a given string."
  end

  defp package do
    [
      name: "sublocator",
      maintainers: ["Weston Littrell"],
      licenses: ["FreeBSD"],
      links: %{"GitHub" => "https://github.com/bhdirect-ebooks/sublocator"}
    ]
  end
end
