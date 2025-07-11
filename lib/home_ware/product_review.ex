defmodule HomeWare.ProductReview do
  use Ecto.Schema
  import Ecto.Changeset

  @statuses ~w(pending approved rejected)a

  schema "product_reviews" do
    field :rating, :integer
    field :title, :string
    field :comment, :string
    field :status, Ecto.Enum, values: @statuses, default: :pending
    field :is_verified_purchase, :boolean, default: false
    field :helpful_votes, :integer, default: 0

    belongs_to :product, HomeWare.Products.Product
    belongs_to :user, HomeWare.Accounts.User
    belongs_to :order, HomeWare.Orders.Order

    timestamps()
  end

  def changeset(review, attrs) do
    review
    |> cast(attrs, [:rating, :title, :comment, :status, :is_verified_purchase, :helpful_votes, :product_id, :user_id, :order_id])
    |> validate_required([:rating, :status, :product_id, :user_id])
    |> validate_inclusion(:status, @statuses)
  end
end
