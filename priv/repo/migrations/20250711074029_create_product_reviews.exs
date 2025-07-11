defmodule HomeWare.Repo.Migrations.CreateProductReviews do
  use Ecto.Migration

  def change do
    create table(:product_reviews, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :rating, :integer
      add :title, :string
      add :comment, :text
      add :status, :string
      add :is_verified_purchase, :boolean
      add :helpful_votes, :integer
      add :product_id, references(:products, on_delete: :delete_all, type: :uuid)
      add :user_id, references(:users, on_delete: :delete_all, type: :uuid)
      add :order_id, references(:orders, on_delete: :nilify_all, type: :uuid)

      timestamps(type: :utc_datetime)
    end

    create index(:product_reviews, [:product_id])
    create index(:product_reviews, [:user_id])
    create index(:product_reviews, [:status])
    create index(:product_reviews, [:rating])

    create unique_index(:product_reviews, [:user_id, :product_id],
             name: :product_reviews_user_product_unique_index
           )
  end
end
