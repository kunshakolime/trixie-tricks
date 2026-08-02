# sshm password auto-fill

Auto-fills passwords for [sshm](https://github.com/Gu1llaum-3/sshm) hosts via
ssh's `SSH_ASKPASS`. Unknown hosts prompt on the TTY and offer to save.

## Setup

```bash
./setup-sshm-askpass.sh
```

Installs (idempotent): `~/.ssh/askpass.sh`, a `host:password` file
`~/.ssh/sshm_passwords`, and `SSH_ASKPASS` exports in `~/.bashrc`.

## Passwords

```bash
vim ~/.ssh/sshm_passwords
```

```
192.0.2.10:examplePassword
root@192.0.2.10:rootExamplePassword
example-host:hostExamplePassword
```

Keys checked in order: `user@host`, `host`, then any alias resolving to that
hostname (ssh prints the resolved `HostName`, not the alias).

## Caveats

- No `:` in passwords (file is `:`-separated).
- No TTY (cron, GUI launcher) → unknown hosts still fail auth.
