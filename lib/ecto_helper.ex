defmodule Api.EctoHelper do
  def if_missing(params, struct, key, value) do
    keys_are_strings =
      params
      |> Map.keys
      |> Enum.map(&is_binary(&1))
      |> Enum.all?

    if Map.get(struct, key, false) do
      params
    else
      Map.put_new(
        params,
        keys_are_strings && Atom.to_string(key) || key,
        value
      )
    end
  end
end
