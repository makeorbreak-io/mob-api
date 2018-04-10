defmodule Api.Enum do

  def avg([]), do: 0
  def avg(list), do: Enum.sum(list) / Enum.count(list)
end
