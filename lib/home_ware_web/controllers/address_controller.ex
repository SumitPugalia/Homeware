defmodule HomeWareWeb.AddressController do
  use HomeWareWeb, :controller

  alias HomeWare.Addresses
  alias HomeWare.Address

  def index(conn, _params) do
    addresses = Addresses.list_user_addresses(conn.assigns.current_user.id)
    render(conn, :index, addresses: addresses)
  end

  def new(conn, _params) do
    changeset = Addresses.change_address(%Address{})
    render(conn, :new, changeset: changeset, action: nil)
  end

  def create(conn, %{"address" => address_params}) do
    address_params = Map.put(address_params, "user_id", conn.assigns.current_user.id)

    case Addresses.create_address(address_params) do
      {:ok, _address} ->
        conn
        |> put_flash(:info, "Address created successfully.")
        |> redirect(to: ~p"/addresses")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset, action: :new)
    end
  end

  def show(conn, %{"id" => id}) do
    address = Addresses.get_address!(id)
    render(conn, :show, address: address)
  end

  def edit(conn, %{"id" => id}) do
    address = Addresses.get_address!(id)
    changeset = Addresses.change_address(address)
    render(conn, :edit, address: address, changeset: changeset)
  end

  def update(conn, %{"id" => id, "address" => address_params}) do
    address = Addresses.get_address!(id)

    case Addresses.update_address(address, address_params) do
      {:ok, address} ->
        conn
        |> put_flash(:info, "Address updated successfully.")
        |> redirect(to: ~p"/addresses/#{address}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, address: address, changeset: changeset, action: :edit)
    end
  end

  def delete(conn, %{"id" => id}) do
    address = Addresses.get_address!(id)
    {:ok, _address} = Addresses.soft_delete_address(address)

    conn
    |> put_flash(:info, "Address deleted successfully.")
    |> redirect(to: ~p"/addresses")
  end
end
