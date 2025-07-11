defmodule HomeWare.Repo.Migrations.CreateAddresses do
  use Ecto.Migration

  def change do
    create table(:addresses, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :type, :string
      add :first_name, :string
      add :last_name, :string
      add :company, :string
      add :address_line_1, :string
      add :address_line_2, :string
      add :address_type, :string
      add :city, :string
      add :state, :string
      add :postal_code, :string
      add :country, :string
      add :phone, :string
      add :is_default, :boolean, default: false
      add :user_id, references(:users, on_delete: :delete_all, type: :uuid)

      timestamps(type: :utc_datetime)
    end

    create index(:addresses, [:user_id])
    create index(:addresses, [:type])
    create index(:addresses, [:is_default])
  end
end
