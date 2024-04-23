defmodule ExCycle.Validations do
  @moduledoc """
  Every Rules applies a list of validation to defined the next datetime.

  Thoses validations could be:

  - `interval` (required)
  - `hour_of_day` (optional)

  """

  alias ExCycle.Validations.{
    DateValidation,
    HourOfDay,
    Interval,
    Lock,
    MinuteOfHour
  }

  @type any_validation ::
          MinuteOfHour.t()
          | HourOfDay.t()
          | Interval.t()
          | Lock.t()
          | DateValidation.t()

  @callback valid?(ExCycle.State.t(), any_validation()) :: boolean()

  @callback next(ExCycle.State.t(), any_validation()) :: ExCycle.State.t()

  @validations_order [
    :minute_of_hour,
    :hour_of_day,
    :interval
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
    locks = locks_for(frequency)
    sort(validations) ++ [DateValidation.new()] ++ locks
  end

  # NOTE maybe `locks_for/1` must be handle directly in the interval validations
  defp locks_for(:yearly), do: [Lock.new(:month), Lock.new(:day)]
  defp locks_for(:monthly), do: [Lock.new(:day)]
  defp locks_for(:weekly), do: [Lock.new(:week_day)]
  defp locks_for(_interval), do: []

  @doc false
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

  defp build_validation(_, validations), do: validations
end
