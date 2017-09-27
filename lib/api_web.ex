defmodule Api.Web do
  @moduledoc """
  A module that keeps using definitions for controllers,
  views and so on.

  This can be used in your application as:

      use Api.Web, :controller
      use Api.Web, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below.
  """

  def model do
    quote do
      use Ecto.Schema

      import Ecto
      import Ecto.Changeset
      import Ecto.Query

      @primary_key {:id, :binary_id, autogenerate: true}
      @foreign_key_type :binary_id
    end
  end

  def controller do
    quote do
      use Phoenix.Controller, namespace: ApiWeb

      alias ApiWeb.Repo

      import Ecto
      import Ecto.Query
      import ApiWeb.Router.Helpers
    end
  end

  def action do
    quote do
      alias ApiWeb.Repo

      import Ecto
      import Ecto.Query
    end
  end

  def view do
    quote do
      use Phoenix.View, root: "lib/api_web/templates", namespace: ApiWeb

      use Phoenix.HTML

      import ApiWeb.Router.Helpers
    end
  end

  def router do
    quote do
      use Phoenix.Router
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end