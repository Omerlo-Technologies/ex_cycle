defmodule ExCycle.StringBuilder do
  @moduledoc """
  This module is in charge of building a stringified version of an `ExCycle.Rule`.

  ## Examples

      iex> ExCycle.Rule.new(:weekly, days: [:monday], hours: [10], minutes: [30])
      ...> StringBuilder.traverse_validations(&stringify/2)
      ...> Enum.join(" ")
      "daily at 10:00, 10:30"

  > NOTE: You **MUST** implement the stringify function on your side.

  """
  @type any_validation :: ExCycle.Validations.any_validation()

  @callback string_params(any_validation()) :: {atom(), [{String.t(), keyword()}]} | nil

  @doc """
  Stringify an `ExCycle.Rule`.

  > Warning: This function is "new" and there is high probability to have breaking changes on next release.

  """
  def traverse_validations(rule, msg_fun) when is_function(msg_fun, 2) do
    params =
      rule.validations
      |> Enum.reject(&(&1.__struct__ == ExCycle.Validations.Lock))
      |> Enum.reverse()
      |> Map.new(fn %module{} = validation ->
        module.string_params(validation)
      end)

    []
    |> put_times(params)
    |> put_days(params)
    |> put_days_of_month(params)
    |> put_interval(params)
    |> Enum.map(fn {unit, msg_opts} -> msg_fun.(unit, msg_opts) end)
  end

  defp put_interval(acc, params) do
    if interval_opts = Map.get(params, :interval, []) do
      [{:interval, interval_opts} | acc]
    else
      acc
    end
  end

  defp put_days_of_month(acc, params) do
    if days_of_month_opts = Map.get(params, :days_of_month) do
      [{:days_of_month, days_of_month_opts} | acc]
    else
      acc
    end
  end

  defp put_days(acc, params) do
    if days_opts = Map.get(params, :days) do
      [{:days, days_opts} | acc]
    else
      acc
    end
  end

  defp put_times(acc, params) do
    hours = Map.get(params, :hours, [])
    minutes = Map.get(params, :minutes, [])

    if msg = build_times_msg(hours, minutes) do
      [msg | acc]
    else
      acc
    end
  end

  defp build_times_msg(hours, minutes)

  defp build_times_msg([], []), do: nil

  defp build_times_msg([], minutes) do
    minutes = Enum.map_join(minutes, ", ", &elem(&1, 0))
    {:minutes, [{minutes, []}]}
  end

  defp build_times_msg(hours, []) do
    for {hour, _opts} <- hours do
      Time.new!(hour, 0, 0)
      |> Calendar.strftime("%H:%M")
      |> then(&{&1, []})
    end
    |> then(&{:times, &1})
  end

  defp build_times_msg(hours, minutes) do
    for {hour, _opts} <- hours, {minute, _opts} <- minutes do
      Time.new!(hour, minute, 0)
      |> Calendar.strftime("%H:%M")
      |> then(&{&1, []})
    end
    |> then(&{:times, &1})
  end
end
