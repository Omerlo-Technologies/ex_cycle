defmodule Example do
  @moduledoc """
  This module provides a compiled example of calling ExCycle.add_rule/3. This compiled
  example is necessary in order to trigger a dialyzer warning if the typespec for that
  function is incorrect.
  """
  def example do
    ExCycle.add_rule(ExCycle.new(), :daily, hours: [1], starts_at: ~D[2024-01-01])
  end
end
