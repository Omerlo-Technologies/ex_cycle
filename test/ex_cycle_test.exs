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
end
