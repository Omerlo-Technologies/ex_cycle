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

## Time zone database

ExCycle support timezones and require a time zone database.
By default, it uses the default time zone database returned by
`Calendar.get_time_zone_database/0`, which defaults to
`Calendar.UTCOnlyTimeZoneDatabase` which only handles "Etc/UTC"
datetimes and returns `{:error, :utc_only_time_zone_database}`
for any other time zone.

Other time zone databases can also be configured. For example,
two of the available options are:

* [`tz`](https://hexdocs.pm/tz/)
* [`tzdata`](https://hexdocs.pm/tzdata/)

To use them, first make sure it is added as a dependency in `mix.exs`.
It can then be configured either via configuration:

```elixir
config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase
```

or by calling `Calendar.put_time_zone_database/1`:

```elixir
Calendar.put_time_zone_database(Tzdata.TimeZoneDatabase)
```

See the proper names in the library installation instructions.

> We apply the same logic as [DateTime from elixir](https://hexdocs.pm/elixir/DateTime.html).

## Documentation

Full documentation could be found at <https://hexdocs.pm/ex_cycle>.

## Quick-start Guide

Create a *cycle* and add rules

```elixir
ExCycle.new()
|> ExCycle.add_rule(:daily, hours: [20, 10])
|> ExCycle.add_rule(:daily, interval: 2, hours: [15])

# Generates every day at 10:00 and 20:00 and every 2 days at 15:00
```

The first element is the frequency that could be one of `secondly`, `minutely`, `hourly`,
`daily`, `monthly` or `yearly`. Then the 2nd parameter is a list of validations options
(like every hours at X).

You can specified a duration using the option `:duration`. The value uses the `Duration` structured, introduced
in elixir `1.17`.

> For every Elixir's versions before `1.17`, we have been cloned this structure to obtain the same behaviour.


### Options

Here the list of option that you can use to generate the rule (using `ExCycle.add_rule/3`).

- `:interval`
- `:hours`
- `:minutes`

### Timezones

As we mention earlier, we support timezone and you can easily generate datetime using the option `timezone: "America/Montreal"` as the code bellow.

```elixir
ExCycle.new()
|> ExCycle.add_rule(:daily, hours: [20, 10], timezone: "America/Montreal")

# Generates every day at 10:00 and 20:00 with timezone America/Montreal
```

### Span

ExCycle support `duration` (using the structs from elixir 1.17), to generates span

```elixir
ExCycle.new()
|> ExCycle.add_rule(:daily, hours: [10], duration: %Duration{hour: 2})
```

This could be combined with `timezone` option to generate span using timezone (**with** DST support).

```elixir
ExCycle.new()
|> ExCycle.add_rule(:daily, hours: [10], duration: %Duration{hour: 2}, timezone: "America/Montreal")

# Generates every day from 10:00 to 12:00 with timezone America/Montreal
```

### Stringify an `ExCycle.Rule`

> Warning: This function is "new" and there is high probability to have breaking changes on next release.

```elixir
stringify = fn(field, msg_opts) ->
  msg =
    Enum.map_join(msg_opts, ", ", fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)

  case field do
    :interval -> msg
    :times -> "at " <> msg
    :minutes -> "every hours at minutes " <> msg
    :days_of_month -> "on the " <> msg
    :days -> "on " <> msg
  end
end

ExCycle.Rule.new(:weekly, days: [:monday], hours: [10], minutes: [30])
|> ExCycle.StringBuilder.traverse_validations(stringify)
|> Enum.join(" ")

# "daily at 10:00, 10:30"
```

## Credits

`ExCycle` is inspired by [Cocktail](https://github.com/peek-travel/cocktail). ExCycle's goal is to improve the handling of Timezones and DST.
