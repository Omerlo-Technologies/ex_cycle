defmodule ExCycle.MixProject do
  use Mix.Project

  @version "0.3.0"

  def project do
    [
      app: :ex_cycle,
      version: @version,
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      description: description(),
      package: package()
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

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
      {:ex_doc, "~> 0.32", only: :dev, runtime: false},
      {:tz, "~> 0.26.5", only: [:dev, :test]}
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
          ExCycle.Validations.MinuteOfHour,
          ExCycle.Validations.HourOfDay,
          ExCycle.Validations.Days,
          ExCycle.Validations.DaysOfMonth,
          ExCycle.Validations.DateExclusion,
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
