defmodule Api.GraphQL.Scalars do
  use Absinthe.Schema.Notation

  scalar :json, name: "JSON" do
    description """
      Represents a stringified JSON resource
    """

    parse fn x -> x end
    serialize fn x -> x end
  end

  scalar :array, name: "Array" do
    description """
      Represents a array of values
    """

    parse fn x -> x end
    serialize fn x -> x end
  end

end
