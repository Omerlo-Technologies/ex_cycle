defmodule ExCycle.Validations.MinuteOfHourTest do
  use ExUnit.Case, async: true
  alias ExCycle.Validations.MinuteOfHour

  setup do
    %{state: ExCycle.State.new(~N[2024-04-04 10:00:00])}
  end

  describe "valid?/2" do
    test "for valid state", %{state: state} do
      validation = MinuteOfHour.new([30])
      state = %{state | next: ~N[2024-04-04 10:30:00]}
      assert MinuteOfHour.valid?(state, validation)
    end

    test "for invalid state", %{state: state} do
      validation = MinuteOfHour.new([30])
      refute MinuteOfHour.valid?(state, validation)
    end
  end

  describe "next/2" do
    test "next minute of same day", %{state: state} do
      validation = MinuteOfHour.new([30])
      new_state = MinuteOfHour.next(state, validation)
      assert new_state.next.minute == 30
    end

    test "next minute of next hour", %{state: state} do
      validation = MinuteOfHour.new([0])
      new_state = MinuteOfHour.next(state, validation)
      assert new_state.next.hour == 11
      assert new_state.next.hour != new_state.origin.hour
    end

    test "next hour of same day with multiples hours", %{state: state} do
      validation = MinuteOfHour.new([15, 30, 45])
      new_state = MinuteOfHour.next(state, validation)
      assert new_state.next.minute == 15
    end
  end
end
