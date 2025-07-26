defmodule HomeWare.Repo.Migrations.AddIsActiveToAddresses do
  use Ecto.Migration

  def change do
    alter table(:addresses) do
      add :is_active, :boolean, default: true, null: false
    end

    create index(:addresses, [:is_active])
  end
end
