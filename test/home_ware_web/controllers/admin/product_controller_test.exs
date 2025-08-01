defmodule HomeWareWeb.Admin.ProductControllerTest do
  use HomeWareWeb.ConnCase

  import Mox
  setup :verify_on_exit!

  alias HomeWare.Products

  setup %{conn: conn} do
    conn = Phoenix.ConnTest.init_test_session(conn, %{})
    {:ok, conn: conn}
  end

  describe "GET /admin/products/new" do
    test "renders new product form", %{conn: conn} do
      conn = log_in_admin_user(conn)
      conn = get(conn, ~p"/admin/products/new")
      assert html_response(conn, 200) =~ "New Product"
    end
  end

  describe "POST /admin/products" do
    setup do
      category = HomeWare.Factory.insert(:category)
      %{category: category}
    end

    test "creates product with valid data", %{conn: conn, category: category} do
      conn = log_in_admin_user(conn)

      product_params = %{
        "name" => "Test Product",
        "description" => "A test product.",
        "category_id" => category.id,
        "brand" => "TestBrand",
        "inventory_quantity" => 10,
        "price" => 99.99,
        "selling_price" => 89.99,
        "model" => "Test Model",
        "product_type" => "Test Type",
        "product_category" => "Test Category",
        "images" => ["https://via.placeholder.com/150"],
        "featured_image" => "https://via.placeholder.com/300",
        "dimensions" => %{"length" => 10, "width" => 5, "height" => 3},
        "specifications" => %{"color" => "White", "material" => "Stainless Steel"},
        "is_active" => true,
        "is_featured" => false
      }

      conn = post(conn, ~p"/admin/products", %{"product" => product_params})
      assert redirected_to(conn) == ~p"/admin/products"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Product created"
    end

    test "creates product with file uploads", %{conn: conn, category: category} do
      HomeWare.UploadMock
      |> expect(:upload_file, 3, fn _path, _dest -> {:ok, "https://mocked.url/image.jpg"} end)

      conn = log_in_admin_user(conn)

      # Create a temporary file for testing
      temp_file = Path.join(System.tmp_dir!(), "test_image.jpg")
      File.write!(temp_file, "fake image content")

      product_params = %{
        "name" => "Test Product with Images",
        "description" => "A test product with uploaded images.",
        "category_id" => category.id,
        "brand" => "TestBrand",
        "inventory_quantity" => 10,
        "price" => 99.99,
        "selling_price" => 89.99,
        "model" => "Test Model",
        "product_type" => "Test Type",
        "product_category" => "Test Category",
        "featured_image" => %Plug.Upload{
          filename: "test_featured.jpg",
          path: temp_file,
          content_type: "image/jpeg"
        },
        "images" => [
          %Plug.Upload{
            filename: "test_image1.jpg",
            path: temp_file,
            content_type: "image/jpeg"
          },
          %Plug.Upload{
            filename: "test_image2.jpg",
            path: temp_file,
            content_type: "image/jpeg"
          }
        ],
        "dimensions" => %{"length" => 10, "width" => 5, "height" => 3},
        "specifications" => %{"color" => "White", "material" => "Stainless Steel"},
        "is_active" => true,
        "is_featured" => false
      }

      conn = post(conn, ~p"/admin/products", %{"product" => product_params})

      # Clean up temp file
      File.rm(temp_file)

      # The upload will be mocked, so the form handling should work
      assert redirected_to(conn) == ~p"/admin/products"
    end

    test "renders form with errors when product creation fails", %{conn: conn, category: category} do
      conn = log_in_admin_user(conn)

      # Invalid product params - missing required fields
      product_params = %{
        # Empty name should fail validation
        "name" => "",
        # Negative price should fail validation
        "price" => -10,
        "category_id" => category.id,
        "brand" => "",
        "model" => "",
        "product_type" => "",
        "product_category" => ""
      }

      conn = post(conn, ~p"/admin/products", %{"product" => product_params})

      # Should render the form again with errors
      assert html_response(conn, 200) =~ "New Product"
      assert html_response(conn, 200) =~ "can&#39;t be blank"
      assert html_response(conn, 200) =~ "must be greater than 0"
    end
  end

  describe "DELETE /admin/products/:id" do
    setup do
      category = HomeWare.Factory.insert(:category)
      product = HomeWare.Factory.insert(:product, %{category_id: category.id})
      %{category: category, product: product}
    end

    test "renders delete confirmation page", %{conn: conn, product: product} do
      conn = log_in_admin_user(conn)
      conn = get(conn, ~p"/admin/products/#{product.id}/confirm_delete")
      assert html_response(conn, 200) =~ "Are you sure you want to delete this product?"
      assert html_response(conn, 200) =~ product.name
    end

    test "deletes product and redirects", %{conn: conn, product: product} do
      conn = log_in_admin_user(conn)
      conn = delete(conn, ~p"/admin/products/#{product.id}")
      assert redirected_to(conn) == ~p"/admin/products"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Product deleted"

      # Product should still exist but be inactive (soft delete)
      deleted_product = Products.get_product!(product.id)
      assert deleted_product.is_active == false
    end
  end
end
