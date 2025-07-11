defmodule HomeWare.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias HomeWare.Repo
  alias HomeWare.Accounts.User

  def register_user(attrs \\ %{}) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  def get_user!(id), do: Repo.get!(User, id)

  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  def get_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    user = Repo.get_by(User, email: email)
    if User.valid_password?(user, password), do: user
  end

  def authenticate_user(email, password) when is_binary(email) and is_binary(password) do
    user = get_user_by_email_and_password(email, password)
    if user, do: {:ok, user}, else: {:error, :invalid_credentials}
  end

  def get_user_by_session_token(token) do
    case Phoenix.Token.verify(HomeWareWeb.Endpoint, "user auth", token, max_age: 2_592_000) do
      {:ok, user_id} -> get_user!(user_id)
      :error -> nil
    end
  end

  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  def change_user(%User{} = user, attrs \\ %{}) do
    User.changeset(user, attrs)
  end

  def change_user_registration(%User{} = user, attrs \\ %{}) do
    User.registration_changeset(user, attrs)
  end

  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  def list_users do
    Repo.all(User)
  end

  def deliver_user_confirmation_instructions(_user, confirmation_fun)
      when is_function(confirmation_fun, 1) do
    # {encoded_token, user_token} = UserToken.generate_email_token(user, "confirm")
    # confirmation_fun.(encoded_token)
    # UserToken.create_user_token(user, user_token, "confirm")
    :ok
  end
end
