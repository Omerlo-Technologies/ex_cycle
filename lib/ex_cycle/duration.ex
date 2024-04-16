if Version.compare(System.version(), "1.17.0") == :lt do
  # This is mainly to create a struct introduces in Elixir v1.17.0
  # https://github.com/elixir-lang/elixir/blob/main/lib/elixir/lib/calendar/duration.ex
  defmodule Duration do
    @derive {Inspect,
             optional: [:year, :month, :week, :day, :hour, :minute, :second, :microsecond]}
    defstruct year: 0,
              month: 0,
              week: 0,
              day: 0,
              hour: 0,
              minute: 0,
              second: 0,
              microsecond: {0, 0}

    @typedoc """
    The duration struct type.
    """
    @type t :: %Duration{
            year: integer,
            month: integer,
            week: integer,
            day: integer,
            hour: integer,
            minute: integer,
            second: integer,
            microsecond: {integer, 0..6}
          }
  end
end
