defmodule QuorumCodingChallenge.Schemas.Vote do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :integer, autogenerate: false}
  schema "votes" do
    belongs_to :bill, QuorumCodingChallenge.Schemas.Bill, foreign_key: :bill_id
    has_many :vote_results, QuorumCodingChallenge.Schemas.VoteResult, foreign_key: :vote_id
  end

  @doc false
  def changeset(vote, attrs) do
    vote
    |> cast(attrs, [:id, :bill_id])
    |> validate_required([:id, :bill_id])
    |> unique_constraint(:id)
  end
end
