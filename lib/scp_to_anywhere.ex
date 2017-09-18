defmodule ScpToAnywhere do
  use Application

  def start(_type, _args) do
    :ssh.daemon(8989, [system_dir: './ssh',
                       ssh_cli: {ScpToAnywhere.SCP, []},
                       subsystems: [],
                       key_cb: ScpToAnywhere.Key,
                       preferred_algorithms: [public_key: [:"ssh-rsa", :"ssh-dss"]]])
  end
end
