defmodule ScpToAnywhere.Password do
  require Logger

  def auth(user, pass, _info, _state) do
    user = List.to_string(user)
    pass = List.to_string(pass)
    Logger.info("#{user} #{pass}")
    case get_password(user) do
      {:ok, user_pass} ->
        pass == user_pass
      {:error, :no_password} ->
        false
    end
  end

  def get_password(user) do
    {_, pass, _} =
      Application.get_env(:scp_to_anywhere, :users)
      |> Enum.find(fn({u, _, _}) -> u == user end)

    if pass do
      {:ok, pass}
    else
      {:error, :no_password}
    end
  end
end
