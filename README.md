# Steam Grid Sync

Copy custom Steam artwork from a Windows or Linux host to a Linux client over SSH/SFTP. The client pulls artwork from `userdata/<id>/config/grid` for Steam accounts present on both computers. Existing client artwork wins by default, including when the host uses a different image extension for the same artwork slot.

This copies image files for existing Steam entries. It leaves games, saves, and shortcut definitions alone. Artwork for a non-Steam shortcut needs the same artwork ID on both sides.

## Install on the Linux client

You need Bash 4.4 or newer, the OpenSSH client tools, and Zenity for the desktop launcher. For example, on Debian or Ubuntu, run `sudo apt install git openssh-client zenity`. On Fedora, use `sudo dnf install git openssh-clients zenity`. On Arch, use `sudo pacman -S git openssh zenity`.

```sh
git clone https://github.com/sidevesh/steam-grid-sync.git
cd steam-grid-sync
bash install.sh
```

Run the installer as your regular Steam user. It installs the command in `~/.local/bin` and adds **Sync Steam Artwork** to the application menu. Run `bash install.sh --cli-only` to use it without Zenity. To update, pull the latest changes and rerun the installer.

## Set up the host

- **Windows:** Enable [OpenSSH Server](https://learn.microsoft.com/en-us/windows-server/administration/openssh/openssh_install_firstuse), start `sshd`, and allow the SSH port on your local network. Use your Windows account password for password authentication. Windows Hello PINs are for local sign-in.
- **Linux:** Install the OpenSSH server package and start its service. On Debian or Ubuntu, run `sudo apt install openssh-server` and `sudo systemctl enable --now ssh`. Other distributions often name the service `sshd`.

Start Steam on the host under the account whose files you want to copy. Sign into the same Steam account on the Linux client at least once so Steam creates its local `userdata` directory. The script caches the host Steam path after a successful first connection.

## Run a sync

Open **Sync Steam Artwork**, enter the host address, SSH username, and port, then choose **Start Sync**. On the first connection, verify the SSH fingerprint against the one shown by the host before trusting it. Microsoft documents how to print the [Windows host fingerprint](https://learn.microsoft.com/en-us/windows-server/administration/openssh/openssh_install_firstuse). With default Linux OpenSSH keys, run `ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub` on the host.

The window shows sync progress and offers to restart Steam on the client when artwork changes. The launcher's **Connection Settings** action also offers a connection test, SSH setup help, and passwordless access management.

From a terminal, run:

```sh
~/.local/bin/steam-grid-sync init
~/.local/bin/steam-grid-sync test-connection
~/.local/bin/steam-grid-sync sync
```

Run `init` once per configuration. The generated `~/.config/steam-grid-sync/config` file has commented options for the client Steam path, Steam account ID, conflict policy, restart behavior, and SSH timeout. `--help` lists command-line overrides. If Steam moves on the host, delete the cached `~/.local/state/steam-grid-sync/host-state` file and repeat discovery using a password or a regular SSH key. XDG directory overrides are honored.

## Passwordless access and automation

The tool uses your existing SSH key if available. You can also enable a dedicated key with **Connection Settings** or `~/.local/bin/steam-grid-sync setup-key`. It adds an entry to the host's OpenSSH `authorized_keys` file and uses the standard read-only SFTP server command. This key can read files that the SSH account can access, including files outside Steam. It cannot use a remote shell or write host files. Passwords are never stored.

With the default Windows OpenSSH configuration, administrator accounts share an authorization file. Use a standard Windows account where practical. [Windows key authentication documentation](https://learn.microsoft.com/en-us/windows-server/administration/openssh/openssh_keymanagement)

After trusting the host and setting up an SSH key, run:

```sh
~/.local/bin/steam-grid-sync sync --non-interactive --no-restart
```

Automation can read the final `RESULT=changed` or `RESULT=unchanged` line. The script returns a nonzero exit status on failure. To revoke the dedicated key, run `~/.local/bin/steam-grid-sync remove-key` using the host password or a regular SSH key.

## Platform support

The computer running the script and receiving artwork must run Linux. The sending computer can run Windows with OpenSSH Server or Linux with OpenSSH Server. Steam discovery runs on the sending computer, so Windows host support does not require a Windows version of the client. macOS and native Windows clients are outside the current support scope.

To uninstall, first revoke any dedicated key you enabled, then remove `~/.local/bin/steam-grid-sync` and `~/.local/share/applications/steam-grid-sync.desktop` (or the launcher under `$XDG_DATA_HOME`). This leaves your Steam artwork and saved connection settings in place.
