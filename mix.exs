defmodule ExCycle.MixProject do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :ex_cycle,
      version: @version,
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      description: description(),
      package: package()
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
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.32", only: :dev, runtime: false}
    ]
  end

  defp docs do
    [
      main: "readme",
      source_ref: @version,
      extras: ["README.md"],
      groups_for_modules: [
        "Internal Modules": [ExCycle.Rule, ExCycle.State, ExCycle.Span],
        Validations: [
          ExCycle.Validations,
          ExCycle.Validations.Interval,
          ExCycle.Validations.HourOfDay,
          ExCycle.Validations.DateValidation,
          ExCycle.Validations.Lock
        ],
        Extra: [Duration]
      ]
    ]
  end

  defp description do
    "ExCycle is a powerful library to generate datetimes following RRules from iCalendar."
  end

  defp package do
    [
      files: ~w[lib mix.exs README.md LICENSE.md],
      maintainers: ["Alexandre Lepretre"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/Omerlo-Technologies/ex_cycle"
      },
      source_url: "https://github.com/Omerlo-Technologies/ex_cycle"
    ]
  end
end
