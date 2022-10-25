defmodule ExAws.CloudSearch.Mixfile do
  use Mix.Project

  @version "0.3.0"
  @service "cloud_search"
  @url "https://github.com/KineticCafe/ex_aws_#{@service}"
  @name __MODULE__
        |> Module.split()
        |> Enum.take(2)
        |> Enum.join(".")

  def project do
    [
      app: :ex_aws_cloud_search,
      version: @version,
      elixir: "~> 1.5",
      build_embedded: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      source_url: @url,
      docs: docs(),
      description: "#{@name} service package",
      package: [
        files: ["lib", "mix.exs", "README.md", "Contributing.md", "Licence.md", ".formatter.exs"],
        licenses: ["MIT"],
        links: %{GitHub: @url}
      ],
      dialyzer: [
        plt_add_apps: [:csquery]
      ]
    ]
  end

  def docs do
    [
      main: "readme",
      extras: ~w(README.md Contributing.md Licence.md Changelog.md),
      source_ref: "v#{@version}",
      source_url: @url
    ]
  end

  defp elixirc_paths(:test) do
    ["lib", "test/support"]
  end

  defp elixirc_paths(_) do
    ["lib"]
  end

  defp deps() do
    [
      ex_aws(),
      {:credo, "~> 1.0", only: :dev, runtime: false},
      {:csquery, "~> 1.0", optional: true},
      {:dialyxir, "~> 1.0", only: :dev, runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:hackney, ">= 0.0.0", only: :test}
    ]
  end

  defp ex_aws() do
    case System.get_env("EX_AWS_PATH") do
      nil -> {:ex_aws, "~> 2.4"}
      path -> {:ex_aws, path: path}
    end
  end
end
