defmodule ExCycle.RuleTest do
  use ExUnit.Case, async: true

  alias ExCycle.Rule

  describe "new/2" do
    test "build rule for: daily at hours [10, 20]" do
      rule = Rule.new(:daily, interval: 2, hours: [20, 10])

      expected_validations = [
        %ExCycle.Validations.HourOfDay{hours: [10, 20]},
        %ExCycle.Validations.Interval{frequency: :daily, value: 2},
        %ExCycle.Validations.DateValidation{}
      ]

      assert rule.validations == expected_validations
    end
  end

  describe "next/1" do
    test "daily" do
      rule =
        Rule.new(:daily, interval: 2, hours: [20, 10])
        |> Map.put(:state, ExCycle.State.new(~D[2024-04-04]))

      rule = Rule.next(rule)
      assert rule.state.next == ~N[2024-04-04 10:00:00]

      rule = Rule.next(rule)
      assert rule.state.next == ~N[2024-04-04 20:00:00]

      rule = Rule.next(rule)
      assert rule.state.next == ~N[2024-04-06 10:00:00]

      rule = Rule.next(rule)
      assert rule.state.next == ~N[2024-04-06 20:00:00]
    end

    test "weekly" do
      rule =
        Rule.new(:weekly, interval: 2, hours: [20, 10])
        |> Map.put(:state, ExCycle.State.new(~D[2024-04-04]))

      rule = Rule.next(rule)
      assert rule.state.next == ~N[2024-04-04 10:00:00]

      rule = Rule.next(rule)
      assert rule.state.next == ~N[2024-04-04 20:00:00]

      rule = Rule.next(rule)
      assert rule.state.next == ~N[2024-04-18 10:00:00]

      rule = Rule.next(rule)
      assert rule.state.next == ~N[2024-04-18 20:00:00]
    end

    test "monthly" do
      rule =
        Rule.new(:monthly, interval: 2, hours: [20, 10])
        |> Map.put(:state, ExCycle.State.new(~D[2024-04-30]))

      rule = Rule.next(rule)
      assert rule.state.next == ~N[2024-04-30 10:00:00]

      rule = Rule.next(rule)
      assert rule.state.next == ~N[2024-04-30 20:00:00]

      rule = Rule.next(rule)
      assert rule.state.next == ~N[2024-06-30 10:00:00]

      rule = Rule.next(rule)
      assert rule.state.next == ~N[2024-06-30 20:00:00]
    end

    test "monthly with leap month" do
      rule =
        Rule.new(:monthly, interval: 1, hours: [20, 10])
        |> Map.put(:state, ExCycle.State.new(~D[2024-01-30]))

      rule = Rule.next(rule)
      assert rule.state.next == ~N[2024-01-30 10:00:00]

      rule = Rule.next(rule)
      assert rule.state.next == ~N[2024-01-30 20:00:00]

      # NOTE: February is skipped because it's an invalid date
      # See [RFC 5545](https://www.rfc-editor.org/rfc/rfc5545) page 42

      rule = Rule.next(rule)
      assert rule.state.next == ~N[2024-03-30 10:00:00]

      rule = Rule.next(rule)
      assert rule.state.next == ~N[2024-03-30 20:00:00]
    end

    test "yearly with leap year" do
      rule =
        Rule.new(:yearly, interval: 2, hours: [20, 10])
        |> Map.put(:state, ExCycle.State.new(~D[2024-02-29]))

      rule = Rule.next(rule)
      assert rule.state.next == ~N[2024-02-29 10:00:00]

      rule = Rule.next(rule)
      assert rule.state.next == ~N[2024-02-29 20:00:00]

      rule = Rule.next(rule)
      assert rule.state.next == ~N[2028-02-29 10:00:00]

      rule = Rule.next(rule)
      assert rule.state.next == ~N[2028-02-29 20:00:00]
    end
  end
end
