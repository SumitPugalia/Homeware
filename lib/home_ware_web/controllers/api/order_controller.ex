defmodule HomeWareWeb.Api.OrderController do
  use HomeWareWeb, :controller

  alias HomeWare.Orders

  def index(conn, params) do
    user = conn.assigns.current_user
    page = Orders.list_orders_for_user(user.id, params)

    conn
    |> put_status(:ok)
    |> json(%{
      orders: Enum.map(page.entries, &order_to_json/1),
      pagination: %{
        page_number: page.page_number,
        page_size: page.page_size,
        total_entries: page.total_entries,
        total_pages: page.total_pages
      }
    })
  end

  def show(conn, %{"id" => id}) do
    user = conn.assigns.current_user

    order = Orders.get_user_order!(user.id, id)

    conn
    |> put_status(:ok)
    |> json(order_to_json(order))
  rescue
    Ecto.NoResultsError ->
      conn
      |> put_status(:not_found)
      |> json(%{error: "Order not found"})
  end

  def create(conn, params) do
    user = conn.assigns.current_user

    case Orders.create_order_with_user(user.id, params) do
      {:ok, order} ->
        conn
        |> put_status(:created)
        |> json(order_to_json(order))

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: format_changeset_errors(changeset)})
    end
  end

  defp order_to_json(order) do
    %{
      id: order.id,
      user_id: order.user_id,
      status: order.status,
      total_amount: order.total_amount,
      shipping_address_id: order.shipping_address_id,
      billing_address_id: order.billing_address_id,
      payment_method: order.payment_method,
      notes: order.notes,
      inserted_at: order.inserted_at,
      updated_at: order.updated_at
    }
  end

  defp format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
