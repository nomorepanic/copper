defmodule Copper.ModuleUtils do
  alias Copper.ModuleUtils

  def name(module), do: module |> Module.split() |> List.first()

  def atom_name(module) do
    module |> ModuleUtils.name() |> String.downcase() |> String.to_atom()
  end

  def submodule(module, submodule) do
    Module.concat([ModuleUtils.name(module), submodule])
  end

  @doc """
  Replaces a fragment of a module name, e.g App.Controllers.My -> App.Schemas.My

  The default index is 1.
  """
  def replace_at(module, replacement, index \\ 1) do
    module
    |> Module.split()
    |> List.replace_at(index, replacement)
    |> Module.concat()
  end

  @doc """
  Replaces and slices a module name, e.g App.Controllers.My -> App.Repo
  """
  def slice_replace(module, replacement, index \\ 1) do
    module
    |> Module.split()
    |> List.replace_at(index, replacement)
    |> Enum.slice(0, 2)
    |> Module.concat()
  end
end
