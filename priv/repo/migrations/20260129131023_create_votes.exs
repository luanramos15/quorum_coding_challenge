defmodule QuorumCodingChallenge.Repo.Migrations.CreateVotes do
  use Ecto.Migration

  def change do
    create table(:votes, primary_key: false) do
      add :id, :integer, primary_key: true
      add :bill_id, references(:bills, on_delete: :delete_all), null: false
    end

    create index(:votes, [:bill_id])
  end
end
