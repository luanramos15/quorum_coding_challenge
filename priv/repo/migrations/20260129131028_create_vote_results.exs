defmodule QuorumCodingChallenge.Repo.Migrations.CreateVoteResults do
  use Ecto.Migration

  def change do
    create table(:vote_results, primary_key: false) do
      add :id, :integer, primary_key: true
      add :legislator_id, references(:legislators, on_delete: :delete_all), null: false
      add :vote_id, references(:votes, on_delete: :delete_all), null: false
      add :vote_type, :integer, null: false
    end

    create index(:vote_results, [:legislator_id])
    create index(:vote_results, [:vote_id])
    create index(:vote_results, [:vote_type])
    create unique_index(:vote_results, [:legislator_id, :vote_id])
  end
end
