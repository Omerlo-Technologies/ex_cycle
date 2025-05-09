defmodule ExCycle.Validations.DateExclusion do
  @moduledoc """
  DateExclusion defines a list of date or datetime to exclude from generated datetimes.

  ## Examples

      iex> %DateExclusion{dates: [~D[2024-01-01], ~N[2024-01-02 10:00:00]]}

  Will exclude the date 2024-01-01 and the datetime 2024-01-02 10:00:00.

  """

  @behaviour ExCycle.Validations
  @behaviour ExCycle.StringBuilder

  alias __MODULE__

  @enforce_keys [:dates]
  defstruct dates: []

  @type t :: %DateExclusion{dates: list(Date.t() | NaiveDateTime.t())}

  @spec new(list(Date.t() | NaiveDateTime.t())) :: t()
  def new(dates) do
    %DateExclusion{
      dates: Enum.map(dates, &parse_datetime/1)
    }
  end

  defp parse_datetime(%Date{} = date), do: date
  defp parse_datetime(%NaiveDateTime{} = datetime), do: datetime

  @impl ExCycle.Validations
  @spec valid?(ExCycle.State.t(), t()) :: boolean()
  def valid?(datetime_state, %DateExclusion{dates: excluded_dates}) do
    !Enum.any?(excluded_dates, &datetimes_equal?(&1, datetime_state.next))
  end

  @impl ExCycle.Validations
  @spec next(ExCycle.State.t(), t()) :: ExCycle.State.t()
  def next(datetime_state, %DateExclusion{dates: excluded_dates}) do
    excluded_date = Enum.find(excluded_dates, &datetimes_equal?(&1, datetime_state.next))

    shift =
      case excluded_date do
        %Date{} -> &(&1 |> Date.add(1) |> NaiveDateTime.new!(~T[00:00:00]))
        %NaiveDateTime{} -> &NaiveDateTime.add(&1, 1, :second)
      end

    ExCycle.State.update_next(datetime_state, shift)
  end

  defp datetimes_equal?(datetime, next_datetime) do
    case datetime do
      %Date{} -> Date.compare(next_datetime, datetime) == :eq
      %NaiveDateTime{} -> NaiveDateTime.compare(next_datetime, datetime) == :eq
    end
  end

  @impl ExCycle.StringBuilder
  def string_params(%DateExclusion{} = date_exclusion) do
    {:exclusions, Enum.map(date_exclusion.dates, &{&1, []})}
  end
end
