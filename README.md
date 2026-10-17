
<p align="right">
  <a href="./README.md">English</a> |
  <a href="./ID.md">Bahasa Indonesia</a>
</p>

## Workflow Setup

When you run `GitActionServer.sh` or `GitActionServer.bat`, the generator creates the following workflow file in your repository:

```text
.github/
└── workflows/
    └── gitactionserver.yml
```

# GitActionServer

**A GitHub Actions Workflow Generator for CLI, Desktop, Docker, Application Setup, and Automated Backups.**

GitActionServer is a lightweight script generator that creates a GitHub Actions workflow for setting up development environments, installing selected applications, configuring CLI or Desktop modes, and automatically committing backup data to the same GitHub repository.

## Project Structure

```text
GitActionServer/
├── GitActionServer.sh
├── GitActionServer.bat
└── README.md
```

- `GitActionServer.sh`: Bash-based workflow generator for Linux and macOS environments.
- `GitActionServer.bat`: Native Windows batch generator that uses PowerShell without requiring Git Bash.
- `README.md`: Project documentation.

## Features

- **Multiple Runner Operating Systems**
  - Ubuntu
  - Windows
  - macOS

- **Environment Modes**
  - Runner CLI
  - Runner Desktop
  - Docker CLI
  - Docker Desktop

- **Selectable Application Categories**
  - Development tools
  - AI tools and Python utilities
  - Database utilities
  - Networking tools
  - Web servers
  - System utilities
  - Multimedia tools

- **Docker Image Selection**
  - Ubuntu
  - Debian
  - Alpine

- **Automated Backup**
  - Configurable intervals from 1 to 5 hours
  - Automatic Git commit and push
  - Backups stored in the same repository as the generated workflow
  - Commits are created only when changes are detected
  - All files inside `backupPush` are included, except `node_modules` directories

## Requirements

- A GitHub repository
- Git installed locally
- Git Bash is optional and is not required by the Windows `.bat` generator
- GitHub Actions enabled for the repository
- Repository write permissions for GitHub Actions

## Installation

### Linux or macOS

Run the Bash generator from inside your local Git repository:

```bash
chmod +x GitActionServer.sh
./GitActionServer.sh
```

### Windows

Run `GitActionServer.bat` from Command Prompt inside your local Git repository.

The Windows generator uses PowerShell, which is included with supported Windows systems. Git must be installed for repository detection and Git operations. Git Bash is not required.

## Generated Workflow

The generator creates:

```text
.github/
└── workflows/
    └── gitactionserver.yml
```

Commit and push the generated workflow to GitHub.

To run it manually:

1. Open your GitHub repository.
2. Navigate to **Actions**.
3. Select **GitActionServer**.
4. Click **Run workflow**.
5. Select the available operating system, environment mode, Docker image, application categories, and backup interval.

## Backup System

GitActionServer uses a dedicated directory named `backupPush`.

### Default Directory Locations

| Operating System | Directory |
|---|---|
| Linux | `$HOME/backupPush` |
| Windows Server | `%USERPROFILE%\Documents\backupPush` |
| macOS | `$HOME/backupPush` |

The exact directory depends on the execution environment and the implementation of the generated workflow.

### Backup Rules

- Only the contents of `backupPush` are synchronized to the repository's `backupPush/` directory.
- Hidden files and configuration files are included.
- Credentials and `.env` files inside the directory are included.
- Every directory named `node_modules` is excluded, including nested directories.
- Files outside `backupPush` are not included.
- Git commits are created only when tracked backup content changes.

### Backup Intervals

Available intervals:

- Every 1 hour
- Every 2 hours
- Every 3 hours
- Every 4 hours
- Every 5 hours

GitHub Actions uses scheduled workflow triggers. Scheduled execution is not guaranteed to occur at an exact time, and GitHub may delay scheduled jobs.

## Important Limitations

### GitHub-Hosted Runners Are Temporary

GitHub-hosted runners are temporary environments. Files installed or created during a job do not automatically persist after the job ends.

The generated workflow must restore previously committed backup data when a new job starts. For persistent environments and data that remain available between jobs, consider using a self-hosted runner.

### Desktop Mode

Installing desktop packages does not automatically provide a remotely accessible desktop session.

Remote desktop access requires additional configuration, including a secure access tunnel and authentication. Do not expose VNC or noVNC ports directly to the public internet without appropriate security controls.

### Docker Mode

Docker containers created by the workflow are temporary. Data that must survive container removal should be stored in a mounted persistent directory such as `backupPush`.

Desktop functionality inside Docker requires additional configuration and is not automatically provided by selecting Docker Desktop mode.

### Repository Permissions

The workflow requires:

```yaml
permissions:
  contents: write
```

Direct pushes may fail if branch protection rules prohibit them or if repository permissions are insufficient.

### Backup Security

All files inside `backupPush` are included except `node_modules` directories. This includes credentials, API keys, tokens, and `.env` files.

A private repository is not a substitute for secure credential management. Anyone with sufficient repository access may be able to read backed-up secrets. Git history can also retain previous copies of files even after they are removed from the latest commit.

Use this backup policy only when you understand and accept those risks.

## Contributing

Contributions, bug reports, and improvements are welcome.

When submitting changes, please keep the project structure simple and document any changes to the generated workflow's behavior.

## License

Choose and add a license file if you intend to distribute or reuse this project publicly.

---

**GitActionServer**  
*Generate the workflow. Configure the environment. Back up what matters.*
