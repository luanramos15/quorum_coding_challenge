defmodule QuorumCodingChallenge.Schemas.Legislator do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :integer, autogenerate: false}
  schema "legislators" do
    field :name, :string

    has_many :bills, QuorumCodingChallenge.Schemas.Bill, foreign_key: :sponsor_id
    has_many :vote_results, QuorumCodingChallenge.Schemas.VoteResult, foreign_key: :legislator_id
  end

  @doc false
  def changeset(legislator, attrs) do
    legislator
    |> cast(attrs, [:id, :name])
    |> validate_required([:id, :name])
    |> unique_constraint(:id)
  end
end
