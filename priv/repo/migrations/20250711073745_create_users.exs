defmodule HomeWare.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :email, :string
      add :hashed_password, :string
      add :confirmed_at, :utc_datetime
      add :first_name, :string
      add :last_name, :string
      add :phone, :string
      add :role, :string
      add :is_active, :boolean

      timestamps(type: :utc_datetime)
    end

    create unique_index(:users, [:email])
    create index(:users, [:role])
    create index(:users, [:is_active])
  end
end
