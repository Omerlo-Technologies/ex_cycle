defmodule ExCycleTest do
  use ExUnit.Case, async: true

  test "with multiples rules" do
    datetimes =
      ExCycle.new()
      |> ExCycle.add_rule(:daily, interval: 2, hours: [20, 10])
      |> ExCycle.add_rule(:daily, interval: 1, hours: [15])
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

  describe "duration" do
    test "every day with 1h of duration" do
      spans =
        ExCycle.new()
        |> ExCycle.add_rule(:daily, interval: 2, hours: [10], duration: %Duration{hour: 1})
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
end
