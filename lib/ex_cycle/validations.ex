defmodule ExCycle.Validations do
  alias ExCycle.Validations.{
    DateValidation,
    HourOfDay,
    Interval,
    Lock
  }

  @type any_validation :: HourOfDay.t() | Interval.t() | Lock.t() | DateValidation.t()

  @callback valid?(ExCycle.State.t(), any_validation()) :: boolean()

  @callback next(ExCycle.State.t(), any_validation()) :: ExCycle.State.t()

  @validation_order [
    :hour_of_day,
    :interval
  ]

  @doc false
  @spec sort(any_validation) :: [any_validation(), ...]
  def sort(validations) do
    for key <- @validation_order, validation = validations[key], !is_nil(validation) do
      validation
    end
  end

  @doc false
  @spec build(Interval.frequency(), keyword()) :: [any_validation(), ...]
  def build(frequency, opts) do
    validations = Enum.reduce(opts, %{}, &build_validation/2)
    locks = locks_for(frequency, validations)
    sort(validations) ++ [DateValidation.new()] ++ locks
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

  defp add_lock(locks, :second, _validations) do
    [Lock.new(:second) | locks]
  end

  defp add_lock(locks, :minute, _validations) do
    [Lock.new(:minute) | locks]
  end

  defp add_lock(locks, :hour, validations) do
    if Map.has_key?(validations, :hour_of_day) do
      locks
    else
      [Lock.new(:hour) | locks]
    end
  end

  defp add_lock(locks, :day, _validations) do
    [Lock.new(:day) | locks]
  end

  defp add_lock(locks, :week_day, _validations) do
    [Lock.new(:week_day) | locks]
  end

  defp add_lock(locks, :month, _validations) do
    [Lock.new(:month) | locks]
  end

  @doc false
  defp build_validation({:hours, hours}, validations) do
    Map.put(validations, :hour_of_day, HourOfDay.new(hours))
  end

  @frequencies [:secondly, :minutely, :hourly, :daily, :weekly, :monthly, :yearly]
  defp build_validation({frequency, interval}, validations) when frequency in @frequencies do
    Map.put(validations, :interval, Interval.new(frequency, interval))
  end

  defp build_validation(_, validations), do: validations
end
