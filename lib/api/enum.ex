defmodule Api.Enum do

  def avg(list) do
    Enum.sum(list) / Enum.count(list)
  end
end
