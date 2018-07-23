defmodule ExAws.CloudSearch.Mixfile do
  use Mix.Project

  @version "0.1.0"
  @service "cloud_search"
  @url "https://github.com/KineticCafe/ex_aws_#{@service}"
  @name __MODULE__ |> Module.split() |> Enum.take(2) |> Enum.join(".")

  @docs [
    main: "readme",
    extras: ["README.md", "Contributing.md", "Licence.md"],
    source_ref: "v#{@version}",
    source_url: @url
  ]

  @description "#{@name} service package"

  @package [
    files: ["lib", "mix.exs", "README.md", "Contributing.md", "Licence.md", ".formatter.exs"],
    licences: ["MIT"],
    links: %{GitHub: @url}
  ]

  # ------------------------------------------------------------

  def project do
    [
      app: :ex_aws_cloud_search,
      version: @version,
      elixir: "~> 1.5",
      build_embedded: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      source_url: @url,
      docs: @docs,
      description: @description,
      package: @package,
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.semaphore": :test,
        "coveralls.html": :test
      ]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps() do
    [
      {:poison, ">= 1.2.0", optional: true},
      {:jsx, "~> 2.8", optional: true},
      {:csquery, "~> 1.0", optional: true},
      {:credo, "~> 0.8", only: :dev, runtime: false},
      {:dialyxir, "~> 0.5", only: :dev, runtime: false},
      {:ex_doc, "~> 0.14", only: :dev, runtime: false},
      {:inch_ex, "~> 0.5", only: :dev, runtime: false},
      {:hackney, ">= 0.0.0", only: [:dev, :test]},
      {:bypass, "~> 0.8", only: :test},
      {:excoveralls, "~> 0.8", only: :test, runtime: false},
      ex_aws()
    ]
  end

  defp ex_aws() do
    case System.get_env("AWS") do
      "LOCAL" -> {:ex_aws, path: "../ex_aws"}
      _ -> {:ex_aws, "~> 2.0"}
    end
  end
end
