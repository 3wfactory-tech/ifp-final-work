defmodule App do
  @moduledoc """
  Documentation for `App`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> App.hello()
      :world

  """
  def hello do
    IO.inspect("App.hello called", label: "App")
    "Teste"
  end
end
