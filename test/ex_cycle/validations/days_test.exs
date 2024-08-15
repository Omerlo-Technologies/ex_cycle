defmodule ExCycle.Validations.DaysTest do
  use ExUnit.Case, async: true
  alias ExCycle.Validations.Days

  # Tuesday 4th april 2024
  @moduletag datetime: ~N[2024-04-04 10:00:00]
  setup %{datetime: datetime} do
    %{state: ExCycle.State.new(datetime)}
  end

  describe "new/1" do
    test "negative weeks are last" do
      validation = Days.new([{-3, :wednesday}, {2, :sunday}, {-1, :monday}, :tuesday])

      assert validation.days == [:tuesday]
      assert validation.days_by_week == [{2, :sunday}, {-3, :wednesday}, {-1, :monday}]
    end

    test "day remove week day" do
      validation = Days.new([:monday, {1, :monday}])
      assert validation.days == [:monday]
      assert validation.days_by_week == []
    end
  end

  describe "valid?/2" do
    @tag datetime: ~N[2024-04-15 20:00:00]
    test "valid by day", %{state: state} do
      validation = Days.new([:monday])
      assert Days.valid?(state, validation)
    end

    @tag datetime: ~N[2024-04-15 20:00:00]
    test "valid by day with week", %{state: state} do
      validation = Days.new([{3, :monday}])
      assert Days.valid?(state, validation)
    end

    test "invalid by day", %{state: state} do
      validation = Days.new([:monday])
      refute Days.valid?(state, validation)
    end

    @tag datetime: ~N[2024-04-22 20:00:00]
    test "invalid by day with week", %{state: state} do
      validation = Days.new([{3, :monday}])
      refute Days.valid?(state, validation)
    end

    @tag datetime: ~N[2024-04-07 20:00:00]
    test "count from the beginning of the month", %{state: state} do
      validation = Days.new([{1, :sunday}])
      assert Days.valid?(state, validation)
    end

    @tag datetime: ~N[2024-04-24 20:00:00]
    test "valid with negative week on last week", %{state: state} do
      validation = Days.new([{-1, :wednesday}])
      assert Days.valid?(state, validation)
    end

    @tag datetime: ~N[2024-04-30 20:00:00]
    test "valid with negative not last week", %{state: state} do
      validation = Days.new([{-1, :tuesday}])
      assert Days.valid?(state, validation)
    end
  end

  describe "next/2" do
    @tag datetime: ~N[2024-04-30 10:00:00]
    test "next should reset the time", %{state: state} do
      validation = Days.new([:monday])
      new_state = Days.next(state, validation)
      assert NaiveDateTime.to_time(new_state.next) == ~T[00:00:00]
    end

    test "next day of same month", %{state: state} do
      validation = Days.new([:monday])
      new_state = Days.next(state, validation)
      assert new_state.next.day == 8
    end

    test "next day of same month and same day", %{state: state} do
      validation = Days.new([:thursday])
      new_state = Days.next(state, validation)
      assert new_state.next.day == 11
    end

    @tag datetime: ~N[2024-04-26 20:00:00]
    test "next day of next month", %{state: state} do
      validation = Days.new([:wednesday])
      new_state = Days.next(state, validation)
      assert new_state.next.day == 1
      assert new_state.next.month == state.origin.month + 1
    end

    @tag datetime: ~N[2023-12-30 10:00:00]
    test "next day of the next year", %{state: state} do
      validation = Days.new([:wednesday])
      new_state = Days.next(state, validation)
      assert new_state.next.day == 3
      assert new_state.next.month == 1
      assert new_state.next.year == 2024
    end

    @tag datetime: ~N[2024-04-04 10:00:00]
    test "with week", %{state: state} do
      validation = Days.new([{3, :monday}])
      new_state = Days.next(state, validation)
      assert new_state.next.day == 15
    end

    @tag datetime: ~N[2024-04-04 10:00:00]
    test "with negative week", %{state: state} do
      validation = Days.new([{-1, :monday}])
      new_state = Days.next(state, validation)
      assert new_state.next.day == 29
      assert new_state.next.month == 4
    end

    @tag datetime: ~N[2024-04-30 10:00:00]
    test "with week next month", %{state: state} do
      validation = Days.new([{1, :monday}])
      new_state = Days.next(state, validation)
      assert new_state.next.day == 6
      assert new_state.next.month == 5
    end

    @tag datetime: ~N[2024-04-30 10:00:00]
    test "with negative week and next month", %{state: state} do
      validation = Days.new([{-1, :monday}])
      new_state = Days.next(state, validation)
      assert new_state.next.day == 27
      assert new_state.next.month == 5
    end
  end
end
