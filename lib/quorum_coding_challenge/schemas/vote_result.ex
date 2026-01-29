defmodule QuorumCodingChallenge.Schemas.VoteResult do
  use Ecto.Schema
  import Ecto.Changeset

  # Vote type constants
  @vote_type_yea 1
  @vote_type_nay 2
  @valid_vote_types [@vote_type_yea, @vote_type_nay]

  @primary_key {:id, :integer, autogenerate: false}
  schema "vote_results" do
    field :vote_type, :integer

    belongs_to :legislator, QuorumCodingChallenge.Schemas.Legislator, foreign_key: :legislator_id
    belongs_to :vote, QuorumCodingChallenge.Schemas.Vote, foreign_key: :vote_id
  end

  @doc "Vote type for yea votes"
  def vote_type_yea, do: @vote_type_yea

  @doc "Vote type for nay votes"
  def vote_type_nay, do: @vote_type_nay

  @doc "All valid vote types"
  def valid_vote_types, do: @valid_vote_types

  @doc "Convert vote type integer to human readable string"
  def vote_type_to_string(1), do: "yea"
  def vote_type_to_string(2), do: "nay"
  def vote_type_to_string(_), do: "unknown"

  @doc false
  def changeset(vote_result, attrs) do
    vote_result
    |> cast(attrs, [:id, :legislator_id, :vote_id, :vote_type])
    |> validate_required([:id, :legislator_id, :vote_id, :vote_type])
    |> validate_inclusion(:vote_type, @valid_vote_types, message: "must be 1 (yea) or 2 (nay)")
    |> unique_constraint(:id)
    |> unique_constraint([:legislator_id, :vote_id])
  end
end
