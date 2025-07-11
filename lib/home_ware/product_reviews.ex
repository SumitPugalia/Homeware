defmodule HomeWare.ProductReviews do
  @moduledoc """
  The ProductReviews context.
  """

  import Ecto.Query, warn: false
  alias HomeWare.Repo
  alias HomeWare.ProductReview

  def list_product_reviews(product_id) do
    ProductReview
    |> where(product_id: ^product_id, status: :approved)
    |> order_by([r], desc: r.inserted_at)
    |> Repo.all()
  end

  def get_product_review!(id), do: Repo.get!(ProductReview, id)

  def create_product_review(attrs \\ %{}) do
    %ProductReview{}
    |> ProductReview.changeset(attrs)
    |> Repo.insert()
  end

  def update_product_review(%ProductReview{} = product_review, attrs) do
    product_review
    |> ProductReview.changeset(attrs)
    |> Repo.update()
  end

  def delete_product_review(%ProductReview{} = product_review) do
    Repo.delete(product_review)
  end

  def change_product_review(%ProductReview{} = product_review, attrs \\ %{}) do
    ProductReview.changeset(product_review, attrs)
  end
end
