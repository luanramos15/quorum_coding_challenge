defmodule QuorumCodingChallenge.Schemas.Bill do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :integer, autogenerate: false}
  schema "bills" do
    field :title, :string

    belongs_to :sponsor, QuorumCodingChallenge.Schemas.Legislator, foreign_key: :sponsor_id
    has_many :votes, QuorumCodingChallenge.Schemas.Vote, foreign_key: :bill_id
  end

  @doc false
  def changeset(bill, attrs) do
    bill
    |> cast(attrs, [:id, :title, :sponsor_id])
    |> validate_required([:id, :title])
    |> unique_constraint(:id)
  end
end
