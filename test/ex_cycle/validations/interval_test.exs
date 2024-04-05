defmodule ExCycle.Validations.IntervalTest do
  use ExUnit.Case, async: true

  alias ExCycle.Validations.Interval

  @moduletag origin: ~D[2024-04-04]
  @moduletag next: ~D[2024-04-04]
  setup %{origin: origin, next: next} do
    %{state: ExCycle.State.new(origin, next)}
  end

  @moduletag interval_value: 1
  setup %{interval_type: type, interval_value: value} do
    %{interval: Interval.new(type, value)}
  end

  describe "daily valid?/2" do
    # those tests also valid hourly, minutly and secondly
    @describetag interval_type: :daily

    @tag next: ~D[2024-04-06]
    @tag interval_value: 2
    test "valid every 2 days", %{state: state, interval: interval} do
      assert Interval.valid?(state, interval)
    end

    @tag next: ~D[2024-04-07]
    @tag interval_value: 2
    test "invalid every 2 days", %{state: state, interval: interval} do
      refute Interval.valid?(state, interval)
    end
  end

  describe "weekly valid?/2" do
    @describetag interval_type: :weekly

    @tag interval_value: 2
    test "valid every 2 weeks", %{state: state, interval: interval} do
      assert Interval.valid?(state, interval)
    end

    @tag next: ~D[2024-04-10]
    @tag interval_value: 2
    test "invalid every 2 weeks", %{state: state, interval: interval} do
      refute Interval.valid?(state, interval)
    end

    @tag origin: ~D[2020-01-01]
    @tag next: ~D[2024-01-01]
    @tag interval_value: 2
    test "with 1 year of 53 weeks", %{state: state, interval: interval} do
      refute Interval.valid?(state, interval)
    end

    # both dates are monday
    @tag origin: ~D[2022-01-03]
    @tag next: ~D[2024-01-01]
    @tag interval_value: 2
    test "every 2 weeks on 1 year", %{state: state, interval: interval} do
      assert Interval.valid?(state, interval)
    end

    # both dates are wednesday
    @tag origin: ~D[2020-01-01]
    @tag next: ~D[2024-01-01]
    @tag interval_value: 2
    test "every 2 weeks with 1 year of 53 weeks", %{state: state, interval: interval} do
      refute Interval.valid?(state, interval)
    end
  end

  describe "monthly valid?/2" do
    @describetag interval_type: :monthly

    @tag origin: ~D[2023-01-01]
    @tag next: ~D[2024-03-05]
    @tag interval_value: 2
    test "valid every 2 months", %{state: state, interval: interval} do
      assert Interval.valid?(state, interval)
    end

    @tag origin: ~D[2024-01-01]
    @tag next: ~D[2024-02-05]
    @tag interval_value: 2
    test "invalid every 2 months", %{state: state, interval: interval} do
      refute Interval.valid?(state, interval)
    end

    @tag origin: ~D[2024-12-01]
    @tag next: ~D[2024-04-05]
    @tag interval_value: 4
    test "with year switch", %{state: state, interval: interval} do
      assert Interval.valid?(state, interval)
    end
  end

  describe "yearly valid?/2" do
    @describetag interval_type: :yearly

    @tag origin: ~D[2023-01-01]
    @tag next: ~D[2025-03-05]
    @tag interval_value: 2
    test "valid every 2 months", %{state: state, interval: interval} do
      assert Interval.valid?(state, interval)
    end

    @tag origin: ~D[2023-01-01]
    @tag next: ~D[2024-02-05]
    @tag interval_value: 2
    test "invalid every 2 months", %{state: state, interval: interval} do
      refute Interval.valid?(state, interval)
    end
  end

  describe "next/2 daily" do
    @describetag interval_type: :daily

    @tag interval_value: 2
    test "next day", %{state: state, interval: interval} do
      state = Interval.next(state, interval)
      assert Date.diff(state.next, state.origin) == 2
    end
  end

  describe "next/2 weekly" do
    @describetag interval_type: :weekly

    @tag interval_value: 2
    test "on the same year", %{state: state, interval: interval} do
      state = Interval.next(state, interval)
      assert Date.diff(state.next, state.origin) == 14
    end

    @tag interval_value: 2
    test "with year shifting", %{state: state, interval: interval} do
      state = Interval.next(state, interval)
      assert Date.diff(state.next, state.origin) == 14
    end
  end

  describe "next/2 monthly" do
    @describetag interval_type: :monthly

    @tag interval_value: 2
    test "on the same year", %{state: state, interval: interval} do
      state = Interval.next(state, interval)
      assert state.next.month == state.origin.month + 2
    end

    @tag interval_value: 2
    @tag origin: ~D[2024-11-04]
    @tag next: ~D[2024-11-04]
    test "with year shifting", %{state: state, interval: interval} do
      state = Interval.next(state, interval)
      assert state.next.month == rem(state.origin.month - 1 + 2, 12) + 1
      assert state.next.year == state.origin.year + div(state.origin.month + 2, 12)
    end

    @tag interval_value: 1
    @tag origin: ~D[2024-01-30]
    @tag next: ~D[2024-01-30]
    test "with invalid day", %{state: state, interval: interval} do
      state = Interval.next(state, interval)
      assert state.next.month == 2
      # 2024 is a Leap year
      assert state.next.day == 29
    end
  end

  describe "next/2 yearly" do
    @describetag interval_type: :yearly

    test "with simple year", %{state: state, interval: interval} do
      state = Interval.next(state, interval)
      assert state.next.year == state.origin.year + 1
    end

    @tag origin: ~D[2024-02-29]
    @tag next: ~D[2024-02-29]
    test "with leap year", %{state: state, interval: interval} do
      state = Interval.next(state, interval)
      assert state.next.day == 28
      assert state.next.month == 2
      assert state.next.year == 2025
    end
  end
end
