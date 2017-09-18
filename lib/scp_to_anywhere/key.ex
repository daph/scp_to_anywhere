defmodule ScpToAnywhere.Key do
  @behaviour :ssh_server_key_api
  require Logger

  def host_key(algo, _opts) do
    key = case algo do
      :"ssh-rsa" ->
        File.read!("./ssh/ssh_host_rsa_key")
      :"ssh-dss" ->
        File.read!("./ssh/ssh_host_dsa_key")
    end

    privkey =
      key
      |> :public_key.pem_decode()
      |> List.first()
      |> :public_key.pem_entry_decode()
    {:ok, privkey}
  end

  def is_auth_key(key, user, _opts) do
    user = List.to_string(user)
    key_text = get_key(user)
    [{authkey, _}] = :public_key.ssh_decode(key_text, :public_key)

    is_allowed?(key, authkey)
  end

  def get_key(user) do
    {_name, _pass, key} =
      Application.get_env(:scp_to_anywhere, :users)
      |> Enum.find(fn({u, _, _}) -> u == user end)
    key
  end

  def is_allowed?(key, key), do: true
  def is_allowed?(_, _), do: false
end
