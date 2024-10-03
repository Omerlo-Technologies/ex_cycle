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

    test "rule starts_at must be used instead of occurrence starts_at" do
      datetimes =
        ExCycle.new()
        |> ExCycle.add_rule(:daily, starts_at: ~D[2024-01-02])
        |> ExCycle.occurrences(~D[2024-01-01])
        |> Enum.take(2)

      assert datetimes == [~N[2024-01-02 00:00:00], ~N[2024-01-03 00:00:00]]
    end

    test "weekly with interval of 3" do
      occurrences =
        ExCycle.new()
        |> ExCycle.add_rule(:weekly,
          interval: 3,
          days: [:monday],
          starts_at: ~D[2024-10-03],
          timezone: "America/New_York",
          hours: [9],
          minutes: [0]
        )
        |> ExCycle.occurrences(~D[2024-10-03])
        |> Enum.take(3)

      assert occurrences == [
               DateTime.new!(~D[2024-10-21], ~T[09:00:00], "America/New_York"),
               DateTime.new!(~D[2024-11-11], ~T[09:00:00], "America/New_York"),
               DateTime.new!(~D[2024-12-02], ~T[09:00:00], "America/New_York")
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

  describe "with DaysOfMonth" do
    test "every 1st and 10th" do
      datetimes =
        ExCycle.new()
        |> ExCycle.add_rule(:daily, days_of_month: [10, 1], starts_at: ~N[2024-01-01 10:00:00])
        |> ExCycle.occurrences(~D[2024-01-01])
        |> Enum.take(5)

      assert datetimes == [
               ~N[2024-01-01 10:00:00],
               ~N[2024-01-10 10:00:00],
               ~N[2024-02-01 10:00:00],
               ~N[2024-02-10 10:00:00],
               ~N[2024-03-01 10:00:00]
             ]
    end
  end

  describe "days" do
    test "every saturday, first monday and last sunday" do
      datetimes =
        ExCycle.new()
        |> ExCycle.add_rule(:daily,
          days: [:saturday, {1, :monday}, {-1, :sunday}],
          starts_at: ~N[2024-01-01 10:00:00]
        )
        |> ExCycle.occurrences(~D[2024-01-01])
        |> Enum.take(10)

      assert datetimes == [
               ~N[2024-01-01 10:00:00],
               ~N[2024-01-06 10:00:00],
               ~N[2024-01-13 10:00:00],
               ~N[2024-01-20 10:00:00],
               ~N[2024-01-27 10:00:00],
               ~N[2024-01-28 10:00:00],
               ~N[2024-02-03 10:00:00],
               ~N[2024-02-05 10:00:00],
               ~N[2024-02-10 10:00:00],
               ~N[2024-02-17 10:00:00]
             ]
    end
  end
end
