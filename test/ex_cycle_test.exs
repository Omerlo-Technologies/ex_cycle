defmodule ExCycleTest do
  use ExUnit.Case, async: true

  import ExCycle.Support.DateTimeSigil

  describe "rules" do
    test "at hour" do
      datetimes =
        ExCycle.new()
        |> ExCycle.add_rule(:daily, hours: [10], starts_at: ~D[2024-01-01])
        |> ExCycle.occurrences(~D[2024-01-01])
        |> Enum.take(2)

      assert datetimes == [~N[2024-01-01 10:00:00], ~N[2024-01-02 10:00:00]]
    end

    test "at minute" do
      datetimes =
        ExCycle.new()
        |> ExCycle.add_rule(:weekly, minutes: [10], starts_at: ~D[2024-01-01])
        |> ExCycle.occurrences(~D[2024-01-01])
        |> Enum.take(2)

      assert datetimes == [~N[2024-01-01 00:10:00], ~N[2024-01-01 01:10:00]]
    end

    test "with multiples rules" do
      datetimes =
        ExCycle.new()
        |> ExCycle.add_rule(:daily, interval: 2, hours: [20, 10], starts_at: ~D[2024-02-29])
        |> ExCycle.add_rule(:daily, interval: 1, hours: [15], starts_at: ~D[2024-01-01])
        |> ExCycle.occurrences(~D[2024-02-29])
        |> Enum.take(9)

      assert datetimes == [
               ~N[2024-02-29 10:00:00],
               ~N[2024-02-29 15:00:00],
               ~N[2024-02-29 20:00:00],
               ~N[2024-03-01 15:00:00],
               ~N[2024-03-02 10:00:00],
               ~N[2024-03-02 15:00:00],
               ~N[2024-03-02 20:00:00],
               ~N[2024-03-03 15:00:00],
               ~N[2024-03-04 10:00:00]
             ]
    end
  end

  describe "excluded dates" do
    test "with dates" do
      datetimes =
        ExCycle.new()
        |> ExCycle.add_rule(:daily, excluded_dates: [~D[2024-01-02]], starts_at: ~D[2024-01-01])
        |> ExCycle.occurrences(~D[2024-01-01])
        |> Enum.take(2)

      assert datetimes == [~N[2024-01-01 00:00:00], ~N[2024-01-03 00:00:00]]
    end

    test "with datetimes" do
      datetimes =
        ExCycle.new()
        |> ExCycle.add_rule(:daily,
          excluded_dates: [~N[2024-01-02 10:00:00]],
          starts_at: ~N[2024-01-01 10:00:00]
        )
        |> ExCycle.occurrences(~D[2024-01-01])
        |> Enum.take(2)

      assert datetimes == [~N[2024-01-01 10:00:00], ~N[2024-01-03 10:00:00]]
    end
  end

  describe "duration" do
    test "every day with 1h of duration" do
      spans =
        ExCycle.new()
        |> ExCycle.add_rule(:daily,
          interval: 2,
          hours: [10],
          duration: %Duration{hour: 1},
          starts_at: ~D[2024-01-01]
        )
        |> ExCycle.occurrences(~D[2024-01-01])
        |> Enum.take(4)

      assert spans ==
               [
                 %ExCycle.Span{from: ~N[2024-01-01 10:00:00], to: ~N[2024-01-01 11:00:00]},
                 %ExCycle.Span{from: ~N[2024-01-03 10:00:00], to: ~N[2024-01-03 11:00:00]},
                 %ExCycle.Span{from: ~N[2024-01-05 10:00:00], to: ~N[2024-01-05 11:00:00]},
                 %ExCycle.Span{from: ~N[2024-01-07 10:00:00], to: ~N[2024-01-07 11:00:00]}
               ]
    end
  end

  describe "timezone" do
    test "rule order" do
      datetimes =
        ExCycle.new()
        |> ExCycle.add_rule(:daily,
          hours: [10],
          timezone: "America/Montreal",
          starts_at: ~D[2024-01-01]
        )
        |> ExCycle.add_rule(:daily,
          hours: [10],
          timezone: "Europe/Paris",
          starts_at: ~D[2024-01-01]
        )
        |> ExCycle.occurrences(~D[2024-01-01])
        |> Enum.take(4)

      assert datetimes == [
               ~Y[2024-01-01 10:00:00 Europe/Paris],
               ~Y[2024-01-01 10:00:00 America/Montreal],
               ~Y[2024-01-02 10:00:00 Europe/Paris],
               ~Y[2024-01-02 10:00:00 America/Montreal]
             ]
    end

    test "every day at 10:00 at America/Montreal" do
      spans =
        ExCycle.new()
        |> ExCycle.add_rule(:daily,
          hours: [10],
          timezone: "America/Montreal",
          starts_at: ~D[2024-01-01]
        )
        |> ExCycle.occurrences(~D[2024-01-01])
        |> Enum.take(4)

      assert spans == [
               ~Y[2024-01-01 10:00:00 America/Montreal],
               ~Y[2024-01-02 10:00:00 America/Montreal],
               ~Y[2024-01-03 10:00:00 America/Montreal],
               ~Y[2024-01-04 10:00:00 America/Montreal]
             ]
    end

    test "with DST summer" do
      spans =
        ExCycle.new()
        |> ExCycle.add_rule(:daily,
          hours: [2],
          timezone: "America/Montreal",
          starts_at: ~D[2024-01-09]
        )
        |> ExCycle.occurrences(~D[2024-03-09])
        |> Enum.take(4)

      assert spans == [
               ~Y[2024-03-09 02:00:00 America/Montreal],
               ~Y[2024-03-11 02:00:00 America/Montreal],
               ~Y[2024-03-12 02:00:00 America/Montreal],
               ~Y[2024-03-13 02:00:00 America/Montreal]
             ]
    end

    test "on span" do
      spans =
        ExCycle.new()
        |> ExCycle.add_rule(:daily,
          hours: [2],
          timezone: "America/Montreal",
          starts_at: ~D[2024-01-09],
          duration: %Duration{hour: 2}
        )
        |> ExCycle.occurrences(~D[2024-01-09])
        |> Enum.take(4)

      assert spans == [
               %ExCycle.Span{
                 from: ~Y[2024-01-09 02:00:00 America/Montreal],
                 to: ~Y[2024-01-09 04:00:00 America/Montreal]
               },
               %ExCycle.Span{
                 from: ~Y[2024-01-10 02:00:00 America/Montreal],
                 to: ~Y[2024-01-10 04:00:00 America/Montreal]
               },
               %ExCycle.Span{
                 from: ~Y[2024-01-11 02:00:00 America/Montreal],
                 to: ~Y[2024-01-11 04:00:00 America/Montreal]
               },
               %ExCycle.Span{
                 from: ~Y[2024-01-12 02:00:00 America/Montreal],
                 to: ~Y[2024-01-12 04:00:00 America/Montreal]
               }
             ]
    end

    test "on span with DST summer, span include in DST" do
      spans =
        ExCycle.new()
        |> ExCycle.add_rule(:daily,
          hours: [2],
          timezone: "America/Montreal",
          starts_at: ~D[2024-01-09],
          duration: %Duration{hour: 1}
        )
        |> ExCycle.occurrences(~D[2024-03-09])
        |> Enum.take(4)

      assert spans == [
               %ExCycle.Span{
                 from: ~Y[2024-03-09 02:00:00 America/Montreal],
                 to: ~Y[2024-03-09 03:00:00 America/Montreal]
               },
               %ExCycle.Span{
                 from: ~Y[2024-03-11 02:00:00 America/Montreal],
                 to: ~Y[2024-03-11 03:00:00 America/Montreal]
               },
               %ExCycle.Span{
                 from: ~Y[2024-03-12 02:00:00 America/Montreal],
                 to: ~Y[2024-03-12 03:00:00 America/Montreal]
               },
               %ExCycle.Span{
                 from: ~Y[2024-03-13 02:00:00 America/Montreal],
                 to: ~Y[2024-03-13 03:00:00 America/Montreal]
               }
             ]
    end

    test "on span with DST summer, DST include in span" do
      spans =
        ExCycle.new()
        |> ExCycle.add_rule(:daily,
          hours: [1],
          timezone: "America/Montreal",
          starts_at: ~D[2024-01-09],
          duration: %Duration{hour: 3}
        )
        |> ExCycle.occurrences(~D[2024-03-09])
        |> Enum.take(4)

      assert spans == [
               %ExCycle.Span{
                 from: ~Y[2024-03-09 01:00:00 America/Montreal],
                 to: ~Y[2024-03-09 04:00:00 America/Montreal]
               },
               %ExCycle.Span{
                 from: ~Y[2024-03-10 01:00:00 America/Montreal],
                 to: ~Y[2024-03-10 04:00:00 America/Montreal]
               },
               %ExCycle.Span{
                 from: ~Y[2024-03-11 01:00:00 America/Montreal],
                 to: ~Y[2024-03-11 04:00:00 America/Montreal]
               },
               %ExCycle.Span{
                 from: ~Y[2024-03-12 01:00:00 America/Montreal],
                 to: ~Y[2024-03-12 04:00:00 America/Montreal]
               }
             ]
    end
  end

  describe "state.origin is the reference" do
    test "for daily event" do
      datetimes =
        ExCycle.new()
        |> ExCycle.add_rule(:daily, interval: 2, hours: [10], starts_at: ~D[2024-01-01])
        |> ExCycle.occurrences(~D[2024-01-02])
        |> Enum.take(2)

      assert datetimes == [~N[2024-01-03 10:00:00], ~N[2024-01-05 10:00:00]]
    end
  end
end
