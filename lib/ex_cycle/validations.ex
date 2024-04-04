defmodule ExCycle.Validations do
  @callback valid?(NaiveDateTime.t(), ExCycle.validation()) :: boolean()

  @callback next(NaiveDateTime.t(), ExCycle.validation()) :: NaiveDateTime.t()
end
