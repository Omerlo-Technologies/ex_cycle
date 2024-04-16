defmodule ExCycle.Validations.IntervalTest do
  use ExUnit.Case, async: true

  alias ExCycle.Validations.Interval

  @moduletag origin: ~N[2024-04-04 00:00:00]
  @moduletag next: ~N[2024-04-04 00:00:00]
  setup %{origin: origin, next: next} do
    %{state: ExCycle.State.new(origin, next)}
  end

  @moduletag interval_value: 1
  setup %{frequency: type, interval_value: value} do
    %{interval: Interval.new(type, value)}
  end

  describe "secondly valid?/2" do
    @describetag frequency: :secondly

    @tag next: ~N[2024-04-05 00:01:30]
    @tag interval_value: 90
    test "valid every 90 seconds", %{state: state, interval: interval} do
      assert Interval.valid?(state, interval)
    end

    @tag next: ~N[2024-04-04 00:00:01]
    @tag interval_value: 2
    test "invalid every 2 seconds", %{state: state, interval: interval} do
      refute Interval.valid?(state, interval)
    end
  end

  describe "minutely valid?/2" do
    @describetag frequency: :minutely

    @tag next: ~N[2024-04-05 01:30:00]
    @tag interval_value: 90
    test "valid every 90 minutes", %{state: state, interval: interval} do
      assert Interval.valid?(state, interval)
    end

    @tag next: ~N[2024-04-04 00:01:00]
    @tag interval_value: 2
    test "invalid every 2 minutes", %{state: state, interval: interval} do
      refute Interval.valid?(state, interval)
    end
  end

  describe "hourly valid?/2" do
    @describetag frequency: :hourly

    @tag next: ~N[2024-04-05 01:00:00]
    @tag interval_value: 25
    test "valid every 25 hours", %{state: state, interval: interval} do
      assert Interval.valid?(state, interval)
    end

    @tag next: ~N[2024-04-04 01:00:00]
    @tag interval_value: 2
    test "invalid every 2 hours", %{state: state, interval: interval} do
      refute Interval.valid?(state, interval)
    end
  end

  describe "daily valid?/2" do
    @describetag frequency: :daily

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
    @describetag frequency: :weekly

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
    @describetag frequency: :monthly

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
    @describetag frequency: :yearly

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

  describe "next/2 secondly" do
    @describetag frequency: :secondly

    @tag interval_value: 2
    test "next seconds", %{state: state, interval: interval} do
      state = Interval.next(state, interval)
      assert NaiveDateTime.diff(state.next, state.origin, :second) == 2
    end
  end

  describe "next/2 minutely" do
    @describetag frequency: :minutely

    @tag interval_value: 2
    test "next minutes", %{state: state, interval: interval} do
      state = Interval.next(state, interval)
      assert NaiveDateTime.diff(state.next, state.origin, :minute) == 2
    end
  end

  describe "next/2 hourly" do
    @describetag frequency: :hourly

    @tag interval_value: 2
    test "next hour", %{state: state, interval: interval} do
      state = Interval.next(state, interval)
      assert NaiveDateTime.diff(state.next, state.origin, :hour) == 2
    end
  end

  describe "next/2 daily" do
    @describetag frequency: :daily

    @tag interval_value: 2
    test "next day", %{state: state, interval: interval} do
      state = Interval.next(state, interval)
      assert Date.diff(state.next, state.origin) == 2
    end
  end

  describe "next/2 weekly" do
    @describetag frequency: :weekly

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
    @describetag frequency: :monthly

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
      assert state.next == ~N[2025-01-04 00:00:00]
    end
  end

  describe "next/2 yearly" do
    @describetag frequency: :yearly

    test "with simple year", %{state: state, interval: interval} do
      state = Interval.next(state, interval)
      assert state.next.year == state.origin.year + 1
    end
  end
end
