defmodule ExCycle.Validations.DaysOfMonthTest do
  use ExUnit.Case, async: true
  alias ExCycle.Validations.DaysOfMonth

  @moduletag datetime: ~N[2024-04-04 10:00:00]
  setup %{datetime: datetime} do
    %{state: ExCycle.State.new(datetime)}
  end

  describe "valid?/2" do
    @tag datetime: ~N[2024-04-20 20:00:00]
    test "for valid state", %{state: state} do
      validation = DaysOfMonth.new([20])
      assert DaysOfMonth.valid?(state, validation)
    end

    test "for invalid state", %{state: state} do
      validation = DaysOfMonth.new([20])
      refute DaysOfMonth.valid?(state, validation)
    end
  end

  describe "next/2" do
    test "next should reset the time", %{state: state} do
      validation = DaysOfMonth.new([20])
      new_state = DaysOfMonth.next(state, validation)
      assert NaiveDateTime.to_time(new_state.next) == ~T[00:00:00]
    end

    test "next day of same month", %{state: state} do
      validation = DaysOfMonth.new([20])
      new_state = DaysOfMonth.next(state, validation)
      assert new_state.next.day == 20
    end

    test "next day of next month", %{state: state} do
      validation = DaysOfMonth.new([1])
      new_state = DaysOfMonth.next(state, validation)
      assert new_state.next.day == 1
      assert new_state.next.month == state.origin.month + 1
    end

    @tag datetime: ~N[2024-12-04 10:00:00]
    test "next day of the next year", %{state: state} do
      validation = DaysOfMonth.new([1])
      new_state = DaysOfMonth.next(state, validation)
      assert new_state.next.day == 1
      assert new_state.next.month == 1
      assert new_state.next.year == 2025
    end

    @tag datetime: ~N[2024-02-04 10:00:00]
    test "next day not include in current month", %{state: state} do
      validation = DaysOfMonth.new([31])
      new_state = DaysOfMonth.next(state, validation)
      assert new_state.next.day == 31
      assert new_state.next.month == 3
    end

    @tag datetime: ~N[2024-12-04 10:00:00]
    test "last day of month", %{state: state} do
      validation = DaysOfMonth.new([-1])
      new_state = DaysOfMonth.next(state, validation)
      assert new_state.next.day == 31
      assert new_state.next.month == 12
    end

    @tag datetime: ~N[2024-01-31 10:00:00]
    test "last day in next month (february)", %{state: state} do
      validation = DaysOfMonth.new([-1])
      new_state = DaysOfMonth.next(state, validation)
      assert new_state.next.day == 29
      assert new_state.next.month == 2
    end
  end
end
