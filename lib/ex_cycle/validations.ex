defmodule ExCycle.Validations do
  @moduledoc """
  Every Rules applies a list of validation to defined the next datetime.

  Thoses validations could be:

  - `interval` (required)
  - `hour_of_day` (optional)

  """

  alias ExCycle.Validations.{
    DateExclusion,
    Days,
    DaysOfMonth,
    HourOfDay,
    Interval,
    Lock,
    MinuteOfHour
  }

  @type any_validation ::
          MinuteOfHour.t()
          | HourOfDay.t()
          | Days.t()
          | DaysOfMonth.t()
          | Interval.t()
          | Lock.t()
          | DateExclusion.t()

  @callback valid?(ExCycle.State.t(), any_validation()) :: boolean()

  @callback next(ExCycle.State.t(), any_validation()) :: ExCycle.State.t()

  @validations_order [
    :minute_of_hour,
    :hour_of_day,
    :days_of_month,
    :days,
    :interval,
    :excluded_dates
  ]

  @doc false
  @spec sort(map()) :: [any_validation(), ...]
  def sort(map) do
    for key <- @validations_order, item = map[key], !is_nil(item) do
      item
    end
  end

  @doc false
  @spec build(Interval.frequency(), keyword()) :: [any_validation(), ...]
  def build(frequency, opts) do
    validations = Enum.reduce(opts, %{}, &build_validation/2)
    locks = locks_for(frequency, Map.keys(validations))
    sort(validations) ++ locks
  end

  defp locks_for(:yearly, validations) do
    add_lock(:second, validations)
    |> add_lock(:minute, validations)
    |> add_lock(:hour, validations)
    |> add_lock(:day, validations)
    |> add_lock(:month, validations)
  end

  defp locks_for(:monthly, validations) do
    add_lock(:second, validations)
    |> add_lock(:minute, validations)
    |> add_lock(:hour, validations)
    |> add_lock(:day, validations)
  end

  defp locks_for(:weekly, validations) do
    add_lock(:second, validations)
    |> add_lock(:minute, validations)
    |> add_lock(:hour, validations)
    |> add_lock(:week_day, validations)
  end

  defp locks_for(:daily, validations) do
    add_lock(:second, validations)
    |> add_lock(:minute, validations)
    |> add_lock(:hour, validations)
  end

  defp locks_for(:hourly, validations) do
    add_lock(:second, validations)
    |> add_lock(:minute, validations)
  end

  defp locks_for(:minutely, validations) do
    add_lock(:second, validations)
  end

  defp locks_for(:secondly, _validations_names) do
    []
  end

  defp add_lock(locks \\ [], type, validations_names)

  @exceptions [:second_of_minute]
  defp add_lock(locks, :second, validations) do
    if Enum.any?(validations, &(&1 in @exceptions)) do
      locks
    else
      [Lock.new(:second) | locks]
    end
  end

  @exceptions [:minute_of_hour, :second_of_minute]
  defp add_lock(locks, :minute, validations) do
    if Enum.any?(validations, &(&1 in @exceptions)) do
      locks
    else
      [Lock.new(:minute) | locks]
    end
  end

  @exceptions [:hour_of_day, :minute_of_hour, :second_of_minute]
  defp add_lock(locks, :hour, validations) do
    if Enum.any?(validations, &(&1 in @exceptions)) do
      locks
    else
      [Lock.new(:hour) | locks]
    end
  end

  @exceptions [:days, :days_of_month]
  defp add_lock(locks, :day, validations) do
    if Enum.any?(validations, &(&1 in @exceptions)) do
      locks
    else
      [Lock.new(:day) | locks]
    end
  end

  @exceptions [:days, :days_of_month]
  defp add_lock(locks, :week_day, validations) do
    if Enum.any?(validations, &(&1 in @exceptions)) do
      locks
    else
      [Lock.new(:week_day) | locks]
    end
  end

  defp add_lock(locks, :month, _validations) do
    [Lock.new(:month) | locks]
  end

  @doc false
  defp build_validation({_opt, []}, validations), do: validations
  defp build_validation({_opt, nil}, validations), do: validations

  defp build_validation({:minutes, minutes}, validations) do
    Map.put(validations, :minute_of_hour, MinuteOfHour.new(minutes))
  end

  defp build_validation({:hours, hours}, validations) do
    Map.put(validations, :hour_of_day, HourOfDay.new(hours))
  end

  @frequencies [:secondly, :minutely, :hourly, :daily, :weekly, :monthly, :yearly]
  defp build_validation({frequency, interval}, validations) when frequency in @frequencies do
    Map.put(validations, :interval, Interval.new(frequency, interval))
  end

  defp build_validation({:days_of_month, days}, validations) do
    Map.put(validations, :days_of_month, DaysOfMonth.new(days))
  end

  defp build_validation({:days, days}, validations) do
    Map.put(validations, :days, Days.new(days))
  end

  defp build_validation({:excluded_dates, dates}, validations) do
    Map.put(validations, :excluded_dates, DateExclusion.new(dates))
  end

  defp build_validation(_, validations), do: validations
end
