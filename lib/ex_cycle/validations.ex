defmodule ExCycle.Validations do
  alias ExCycle.Validations.{
    HourOfDay,
    Interval
  }

  @type any_validation :: HourOfDay.t() | Interval.t()

  @callback valid?(ExCycle.State.t(), any_validation()) :: boolean()

  @callback next(ExCycle.State.t(), any_validation()) :: ExCycle.State.t()
end
