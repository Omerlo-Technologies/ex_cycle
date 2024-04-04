defmodule ExCycle.Validations do
  @callback valid?(ExCycle.datetime(), ExCycle.validation()) :: boolean()

  @callback next(ExCycle.datetime(), ExCycle.validation()) :: any()
end
