defmodule HomeWare.Repo.Migrations.CreateAddresses do
  use Ecto.Migration

  def change do
    create table(:addresses) do
      add :type, :string, null: false
      add :first_name, :string, null: false
      add :last_name, :string, null: false
      add :company, :string
      add :address_line_1, :string, null: false
      add :address_line_2, :string
      add :city, :string, null: false
      add :state, :string, null: false
      add :postal_code, :string, null: false
      add :country, :string, null: false
      add :phone, :string
      add :is_default, :boolean, default: false, null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:addresses, [:user_id])
    create index(:addresses, [:type])
    create index(:addresses, [:is_default])
  end
end
