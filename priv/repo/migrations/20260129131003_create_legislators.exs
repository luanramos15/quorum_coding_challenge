defmodule QuorumCodingChallenge.Repo.Migrations.CreateLegislators do
  use Ecto.Migration

  def change do
    create table(:legislators, primary_key: false) do
      add :id, :integer, primary_key: true
      add :name, :string, null: false
    end

    create index(:legislators, [:name])
  end
end
