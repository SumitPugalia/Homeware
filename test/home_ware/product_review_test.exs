defmodule HomeWare.ProductReviewTest do
  use HomeWare.DataCase

  alias HomeWare.ProductReview
  alias HomeWare.Factory

  describe "product_review changeset" do
    test "changeset with valid attributes" do
      product_review = Factory.build(:product_review)
      changeset = ProductReview.changeset(%ProductReview{}, Map.from_struct(product_review))
      assert changeset.valid?
    end

    test "changeset with invalid rating" do
      changeset = ProductReview.changeset(%ProductReview{}, %{rating: 6})
      refute changeset.valid?
      assert "must be less than or equal to 5" in errors_on(changeset).rating
    end

    test "changeset with zero rating" do
      changeset = ProductReview.changeset(%ProductReview{}, %{rating: 0})
      refute changeset.valid?
      assert "must be greater than 0" in errors_on(changeset).rating
    end

    test "changeset with invalid status" do
      changeset = ProductReview.changeset(%ProductReview{}, %{status: :invalid})
      refute changeset.valid?
      assert "is invalid" in errors_on(changeset).status
    end

    test "changeset with short title" do
      changeset = ProductReview.changeset(%ProductReview{}, %{title: "Hi"})
      refute changeset.valid?
      assert "should be at least 3 character(s)" in errors_on(changeset).title
    end

    test "changeset with short content" do
      changeset = ProductReview.changeset(%ProductReview{}, %{content: "Short"})
      refute changeset.valid?
      assert "should be at least 10 character(s)" in errors_on(changeset).content
    end

    test "changeset with missing required fields" do
      changeset = ProductReview.changeset(%ProductReview{}, %{})
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).rating
      assert "can't be blank" in errors_on(changeset).title
      assert "can't be blank" in errors_on(changeset).content
    end
  end
end
