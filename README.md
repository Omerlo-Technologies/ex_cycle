# ExCycle

`ExCycle` is a powerful library to generate datetimes following RRules from iCalendar.

```elixir
iex> ExCycle.new()
...> |> ExCycle.add_rule(:daily, interval: 2, hours: [20, 10]
...> |> ExCycle.add_rule(:daily, interval: 1, hours: [15]
...> |> ExCycle.occurrences(~D[2024-02-29]
...> |> Enum.take(5)
[~N[2024-02-29 10:00:00], ~N[2024-02-29 15:00:00], ~N[2024-02-29 20:00:00], ~N[2024-03-01 15:00:00], ~N[2024-03-02 10:00:00]]
```

## Installation

`ExCycle` is available on [Hex](https://hex.pm/packages/ex_cycle) and can be installed
by adding `ex_cycle` to your list of dependencies in `mix.exs`.

```elixir
def deps do
  [
    {:ex_cycle, "~> 0.1.0"}
  ]
end
```

## Documentation

Full documentation could be found at <https://hexdocs.pm/ex_cycle>.

## Quick-start Guide

Create a *cycle* using

```elixir
iex> ExCycle.new(:daily, hours: [20, 10])
```

The first element is the frequency that could be one of `secondly`, `minutely`, `hourly`,
`daily`, `monthly` or `yearly`. Then the 2nd parameter is a list of validations options
(like every hours at X).

You can specified a duration using the option `:duration` that use the structure `Duration` introduce
in elixir `1.17`.

> For every Elixir's versions before `1.17` we clone this structure to obtain the same behaviour.
