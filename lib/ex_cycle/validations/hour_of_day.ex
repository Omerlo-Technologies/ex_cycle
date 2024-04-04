defmodule ExCycle.Validations.HourOfDay do
  @behaviour ExCycle.Validations

  alias __MODULE__

  @enforce_keys [:hours]
  defstruct hours: []

  @type t :: %HourOfDay{hours: list(non_neg_integer())}

  @doc """

  ## Examples

      iex> valid?(~N[2024-04-04 20:00:00Z], %HourOfDay{hours: [20]})
      true

      iex> valid?(~N[2024-04-04 21:00:00Z], %HourOfDay{hours: [20]})
      false

  """
  @spec valid?(NaiveDateTime.t(), t()) :: boolean()
  def valid?(naive_datetime, %HourOfDay{hours: hours}) do
    Enum.any?(hours, &(&1 == naive_datetime.hour))
  end

  @doc """

  ## Examples

      iex> next(~N[2024-04-04 20:00:00Z], %HourOfDay{hours: [21]})
      ~N[2024-04-04 21:00:00Z]

      iex> next(~N[2024-04-04 20:00:00Z], %HourOfDay{hours: [10]})
      ~N[2024-04-05 10:00:00Z]

      iex> next(~N[2024-04-04 20:00:00Z], %HourOfDay{hours: [22, 11]})
      ~N[2024-04-04 22:00:00Z]

  """
  @spec next(NaiveDateTime.t(), t()) :: NaiveDateTime.t()
  def next(naive_datetime, %HourOfDay{hours: _hours}) do
    naive_datetime
    # Find the nearest hour >= datetime.hour
    # If it doesn't exist : get the lower hour
  end
end
