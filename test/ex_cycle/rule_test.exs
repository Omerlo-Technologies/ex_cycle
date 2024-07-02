defmodule ExCycle.RuleTest do
  use ExUnit.Case, async: true

  alias ExCycle.Rule

  describe "new/2" do
    test "build rule for: daily at hours [10, 20] for 1h" do
      rule = Rule.new(:daily, interval: 2, hours: [20, 10], duration: %Duration{hour: 1})

      expected_validations = [
        %ExCycle.Validations.HourOfDay{hours: [10, 20]},
        %ExCycle.Validations.Interval{frequency: :daily, value: 2},
        %ExCycle.Validations.DateValidation{},
        %ExCycle.Validations.Lock{unit: :minute},
        %ExCycle.Validations.Lock{unit: :second}
      ]

      assert rule.validations == expected_validations
      assert rule.duration == %Duration{hour: 1}
    end

    test "zero duration is removed" do
      rule = Rule.new(:daily, duration: %Duration{})
      assert is_nil(rule.duration)
    end
  end

  describe "count option" do
    test "rule's state must be exhausted" do
      rule = Rule.new(:daily, count: 2) |> Rule.init(~D[2024-04-04])
      assert rule.state.next

      rule = Rule.next(rule)
      assert rule.state.next

      rule = Rule.next(rule)
      assert rule.state.exhausted?
    end
  end

  describe "until option" do
    test "rule's state must be exhausted" do
      rule = Rule.new(:daily, until: ~D[2024-04-05]) |> Rule.init(~D[2024-04-04])
      assert rule.state.next

      rule = Rule.next(rule)
      assert rule.state.next == ~N[2024-04-05 00:00:00]

      rule = Rule.next(rule)
      assert rule.state.exhausted?
    end
  end

  describe "next/1" do
    test "daily at 20 and 10" do
      rule = Rule.new(:daily, interval: 2, hours: [20, 10]) |> Rule.init(~D[2024-04-04])
      assert rule.state.next == ~N[2024-04-04 10:00:00]

      rule = Rule.next(rule)
      assert rule.state.next == ~N[2024-04-04 20:00:00]

      rule = Rule.next(rule)
      assert rule.state.next == ~N[2024-04-06 10:00:00]

      rule = Rule.next(rule)
      assert rule.state.next == ~N[2024-04-06 20:00:00]
    end

    test "daily" do
      rule = Rule.new(:daily, interval: 2) |> Rule.init(~D[2024-04-04])
      assert rule.state.next == ~N[2024-04-04 00:00:00]

      rule = Rule.next(rule)
      assert rule.state.next == ~N[2024-04-06 00:00:00]

      rule = Rule.next(rule)
      assert rule.state.next == ~N[2024-04-08 00:00:00]

      rule = Rule.next(rule)
      assert rule.state.next == ~N[2024-04-10 00:00:00]
    end

    test "weekly" do
      rule = Rule.new(:weekly, interval: 2) |> Rule.init(~D[2024-04-04])
      assert rule.state.next == ~N[2024-04-04 00:00:00]

      rule = Rule.next(rule)
      assert rule.state.next == ~N[2024-04-18 00:00:00]

      rule = Rule.next(rule)
      assert rule.state.next == ~N[2024-05-02 00:00:00]
    end

    test "weekly on monday and tuesday" do
      rule = Rule.new(:weekly, days: [:monday, :tuesday]) |> Rule.init(~D[2024-04-01])
      assert rule.state.next == ~N[2024-04-01 00:00:00]

      rule = Rule.next(rule)
      assert rule.state.next == ~N[2024-04-02 00:00:00]

      rule = Rule.next(rule)
      assert rule.state.next == ~N[2024-04-08 00:00:00]
    end

    test "monthly" do
      rule = Rule.new(:monthly, interval: 2) |> Rule.init(~D[2024-04-30])
      assert rule.state.next == ~N[2024-04-30 00:00:00]

      rule = Rule.next(rule)
      assert rule.state.next == ~N[2024-06-30 00:00:00]

      rule = Rule.next(rule)
      assert rule.state.next == ~N[2024-08-30 00:00:00]

      rule = Rule.next(rule)
      assert rule.state.next == ~N[2024-10-30 00:00:00]
    end

    test "monthly with leap month" do
      rule = Rule.new(:monthly, interval: 1) |> Rule.init(~D[2024-01-30])
      assert rule.state.next == ~N[2024-01-30 00:00:00]

      # NOTE: February is skipped because it's an invalid date
      # See [RFC 5545](https://www.rfc-editor.org/rfc/rfc5545) page 42

      rule = Rule.next(rule)
      assert rule.state.next == ~N[2024-03-30 00:00:00]

      rule = Rule.next(rule)
      assert rule.state.next == ~N[2024-04-30 00:00:00]
    end

    test "yearly with leap year" do
      rule = Rule.new(:yearly, interval: 2) |> Rule.init(~D[2024-02-29])
      assert rule.state.next == ~N[2024-02-29 00:00:00]

      rule = Rule.next(rule)
      assert rule.state.next == ~N[2028-02-29 00:00:00]

      rule = Rule.next(rule)
      assert rule.state.next == ~N[2032-02-29 00:00:00]
    end
  end
end
