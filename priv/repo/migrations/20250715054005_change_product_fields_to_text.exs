defmodule HomeWare.Repo.Migrations.ChangeProductFieldsToText do
  use Ecto.Migration

  def change do
    alter table(:products) do
      modify :description, :text
      modify :model, :text
      modify :images, {:array, :text}
    end
  end
end
