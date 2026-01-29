defmodule QuorumCodingChallenge.Repo.Migrations.CreateBills do
  use Ecto.Migration

  def change do
    create table(:bills, primary_key: false) do
      add :id, :integer, primary_key: true
      add :title, :string, null: false
      add :sponsor_id, references(:legislators, on_delete: :nilify_all), null: true
    end

    create index(:bills, [:sponsor_id])
    create index(:bills, [:title])
  end
end
