defmodule ExCycle.Validations.DateExclusionTest do
  use ExUnit.Case, async: true
  alias ExCycle.Validations.DateExclusion

  setup do
    %{state: ExCycle.State.new(~N[2024-04-04 10:00:00])}
  end

  describe "valid?/2" do
    test "for valid state", %{state: state} do
      validation = DateExclusion.new([])
      assert DateExclusion.valid?(state, validation)
    end

    test "for excluded date", %{state: state} do
      validation = DateExclusion.new([~D[2024-04-04]])
      refute DateExclusion.valid?(state, validation)
    end

    test "for excluded datetime", %{state: state} do
      validation = DateExclusion.new([~N[2024-04-04 10:00:00]])
      refute DateExclusion.valid?(state, validation)
    end
  end

  describe "next/2" do
    test "for date", %{state: state} do
      validation = DateExclusion.new([~D[2024-04-04]])
      new_state = DateExclusion.next(state, validation)
      assert new_state.next == ~N[2024-04-05 00:00:00]
    end

    test "for datetime", %{state: state} do
      validation = DateExclusion.new([~N[2024-04-04 10:00:00]])
      new_state = DateExclusion.next(state, validation)
      assert new_state.next == ~N[2024-04-04 10:00:01]
    end
  end
end
