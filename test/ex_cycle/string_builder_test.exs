defmodule ExCycle.StringBuilderTest do
  use ExUnit.Case, async: true

  alias ExCycle.StringBuilder

  test "every 2 days at 10:00" do
    rule = ExCycle.Rule.new(:daily, interval: 2, hours: [10])
    string = StringBuilder.traverse_validations(rule, &stringify/2) |> Enum.join(" ")
    assert string == "every 2 days at 10:00"
  end

  test "daily at 10:00, 10:30" do
    rule = ExCycle.Rule.new(:daily, hours: [10], minutes: [0, 30])
    string = StringBuilder.traverse_validations(rule, &stringify/2) |> Enum.join(" ")
    assert string == "daily at 10:00, 10:30"
  end

  test "weekly every hours at minutes 0, 30" do
    rule = ExCycle.Rule.new(:weekly, minutes: [0, 30])
    string = StringBuilder.traverse_validations(rule, &stringify/2) |> Enum.join(" ")
    assert string == "weekly every hours at minutes 0, 30"
  end

  test "monthly, on the 1st, 30" do
    rule = ExCycle.Rule.new(:monthly, days_of_month: [1, 30])
    string = StringBuilder.traverse_validations(rule, &stringify/2) |> Enum.join(" ")
    assert string == "monthly on the 1st, 30th"
  end

  test "weekly on monday at 10:30" do
    rule = ExCycle.Rule.new(:weekly, days: [:monday], hours: [10], minutes: [30])
    string = StringBuilder.traverse_validations(rule, &stringify/2) |> Enum.join(" ")
    assert string == "weekly on monday at 10:30"
  end

  defp stringify(field, msg_opts) do
    msg =
      Enum.map_join(msg_opts, ", ", fn {msg, opts} ->
        Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
          opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
        end)
      end)

    case field do
      :interval -> msg
      :times -> "at " <> msg
      :minutes -> "every hours at minutes " <> msg
      :days_of_month -> "on the " <> msg
      :days -> "on " <> msg
    end
  end
end
