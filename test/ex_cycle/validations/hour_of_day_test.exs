defmodule ExCycle.Validations.HourOfDayTest do
  use ExUnit.Case, async: true
  alias ExCycle.Validations.HourOfDay

  setup do
    %{state: ExCycle.State.new(~N[2024-04-04 10:00:00])}
  end

  describe "valid?/2" do
    test "for valid state", %{state: state} do
      validation = HourOfDay.new([20])
      state = %{state | next: ~N[2024-04-04 20:00:00]}
      assert HourOfDay.valid?(state, validation)
    end

    test "for invalid state", %{state: state} do
      validation = HourOfDay.new([20])
      refute HourOfDay.valid?(state, validation)
    end
  end

  describe "next/2" do
    test "next hour of same day", %{state: state} do
      validation = HourOfDay.new([20])
      new_state = HourOfDay.next(state, validation)
      assert new_state.next.hour == 20
    end

    test "next hour of next day", %{state: state} do
      validation = HourOfDay.new([6])
      new_state = HourOfDay.next(state, validation)
      assert new_state.next.hour == 6
      assert new_state.next.day != new_state.origin.day
    end

    test "next hour of same day with multiples hours", %{state: state} do
      validation = HourOfDay.new([22, 20, 6])
      new_state = HourOfDay.next(state, validation)
      assert new_state.next.hour == 20
    end
  end
end
