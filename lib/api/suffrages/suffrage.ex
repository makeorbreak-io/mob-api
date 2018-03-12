defmodule Api.Suffrages.Suffrage do
  use Ecto.Schema
  import Ecto.Changeset

  alias Api.Suffrages.{Category, Candidate, Vote, PaperVote}
  alias Api.Competitions.Competition

  @valid_attrs ~w(
    voting_started_at
    voting_ended_at
    category_id
    competition_id
  )a

  @required_attrs ~w(
    competition_id
  )a

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "suffrages" do
    field :voting_started_at, :utc_datetime
    field :voting_ended_at, :utc_datetime
    field :podium, {:array, :binary_id}

    belongs_to :category, Category
    belongs_to :competition, Competition

    has_many :votes, Vote
    has_many :paper_votes, PaperVote
    has_many :candidates, Candidate

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @valid_attrs)
    |> validate_required(@required_attrs)
    |> _cant_change(:voting_started_at)
    |> _cant_change(:voting_ended_at)
    |> assoc_constraint(:competition)
  end

  defp _cant_change(%Ecto.Changeset{changes: changes, data: data} = changeset, field) do
    with {:ok, old} <- Map.fetch(data, field),
         {:ok, new} <- Map.fetch(changes, field),
         true <- old != nil,
         true <- old != new
    do
      add_error(changeset, field, "can't be changed")
    else
      _ -> changeset
    end
  end
end
