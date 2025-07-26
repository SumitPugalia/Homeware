defmodule HomeWare.Addresses do
  @moduledoc """
  The Addresses context.
  """

  import Ecto.Query, warn: false
  alias HomeWare.Repo
  alias HomeWare.Address

  def list_user_addresses(user_id) do
    Address
    |> where([a], a.user_id == ^user_id and a.is_active == true)
    |> Repo.all()
  end

  def get_address!(id), do: Repo.get!(Address, id)

  def create_address(attrs \\ %{}) do
    %Address{}
    |> Address.changeset(attrs)
    |> Repo.insert()
  end

  def update_address(%Address{} = address, attrs) do
    address
    |> Address.changeset(attrs)
    |> Repo.update()
  end

  def delete_address(%Address{} = address) do
    Repo.delete(address)
  end

  def soft_delete_address(%Address{} = address) do
    address
    |> Address.changeset(%{is_active: false})
    |> Repo.update()
  end

  def change_address(%Address{} = address, attrs \\ %{}) do
    Address.changeset(address, attrs)
  end
end
