defmodule HomeWare.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :email, :string, null: false
      add :hashed_password, :string, null: false
      add :confirmed_at, :naive_datetime
      add :first_name, :string
      add :last_name, :string
      add :phone, :string
      add :role, :string, default: "customer", null: false
      add :is_active, :boolean, default: true, null: false

      timestamps()
    end

    create unique_index(:users, [:email])
    create index(:users, [:role])
    create index(:users, [:is_active])
  end
end
