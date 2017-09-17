defmodule ScpToAnywhere do
  use Application

  def start(_type, _args) do
    :ssh.daemon(8989, [{:system_dir, './ssh'}, {:ssh_cli, {ScpToAnywhere.SCP, []}}])
  end
end
