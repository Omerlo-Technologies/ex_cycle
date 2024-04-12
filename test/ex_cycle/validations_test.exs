defmodule ExCycle.ValidationsTest do
  use ExUnit.Case, async: true

  alias ExCycle.Validations

  describe "sort/1" do
    test "simple test" do
      hour_of_day = Validations.HourOfDay.new([10])
      interval = Validations.Interval.new(:daily)
      validations = %{interval: interval, hour_of_day: hour_of_day}
      sorted_validations = Validations.sort(validations)
      assert sorted_validations == [hour_of_day, interval]
    end
  end
end
