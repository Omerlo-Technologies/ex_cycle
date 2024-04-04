defmodule ExCycle.Validations.HourOfDay do
  @behaviour ExCycle.Validations

  alias __MODULE__

  @enforce_keys [:hours]
  defstruct hours: []

  @type t :: %HourOfDay{hours: list(non_neg_integer())}

  @doc """

  ## Examples

      iex> valid?(~U[2024-04-04 20:00:00Z], %HourOfDay{hours: [20]})
      true

      iex> valid?(~U[2024-04-04 21:00:00Z], %HourOfDay{hours: [20]})
      false

  """
  def valid?(datetime, %HourOfDay{hours: hours}) do
    Enum.any?(hours, &(&1 == datetime.hour))
  end

  @doc """

  ## Examples

      iex> next(~U[2024-04-04 20:00:00Z], %HourOfDay{hours: [21]})
      ~U[2024-04-04 21:00:00Z]

      iex> next(~U[2024-04-04 20:00:00Z], %HourOfDay{hours: [10]})
      ~U[2024-04-05 10:00:00Z]

  """
  def next(datetime, %HourOfDay{hours: _hours}) do
    datetime
  end
end
