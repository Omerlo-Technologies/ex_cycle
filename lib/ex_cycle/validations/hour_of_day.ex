defmodule ExCycle.Validations.HourOfDay do
  @behaviour ExCycle.Validations

  alias __MODULE__

  @enforce_keys [:hours]
  defstruct hours: []

  @type t :: %HourOfDay{hours: list(non_neg_integer())}

  def new(hours), do: %HourOfDay{hours: Enum.sort(hours)}

  @doc """

  ## Examples

      iex> valid?(~N[2024-04-04 20:00:00], %HourOfDay{hours: [20]})
      true

      iex> valid?(~N[2024-04-04 21:00:00], %HourOfDay{hours: [20]})
      false

  """
  @spec valid?(NaiveDateTime.t(), t()) :: boolean()
  def valid?(naive_datetime, %HourOfDay{hours: hours}) do
    Enum.any?(hours, &(&1 == naive_datetime.hour))
  end

  @doc """

  ## Examples

      iex> next(~N[2024-04-04 20:00:00], %HourOfDay{hours: [21]})
      ~N[2024-04-04 21:00:00]

      iex> next(~N[2024-04-04 20:00:00], %HourOfDay{hours: [10]})
      ~N[2024-04-05 10:00:00]

      iex> next(~N[2024-04-04 20:00:00], %HourOfDay{hours: [10, 22]})
      ~N[2024-04-04 22:00:00]

  """
  @spec next(NaiveDateTime.t(), t()) :: NaiveDateTime.t()
  def next(naive_datetime, %HourOfDay{hours: hours}) do
    next_hour = Enum.find(hours, &(&1 >= naive_datetime.hour)) || hd(hours)
    diff = Integer.mod(next_hour - naive_datetime.hour, 24)
    NaiveDateTime.add(naive_datetime, diff, :hour)
  end
end
