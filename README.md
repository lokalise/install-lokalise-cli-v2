# GitHub Action to Install Lokalise CLI v2

Not your father's CLI installer — this one's fast, flexible, and ready to Lokalise like a pro. This action installs the [Lokalise CLI v2](https://github.com/lokalise/lokalise-cli-2-go), a command-line tool for interacting with your Lokalise projects. You can use it to upload translations, download files, manage keys, and more.

## Usage

```yaml
- name: Install Lokalise CLI v2
  uses: lokalise/install-lokalise-cli-v2@v2.1.0
  with:
    force-install: true         # Optional: force reinstallation even if already installed
    target-version: 3.1.3       # Optional: specify CLI version (e.g., 3.1.1). Defaults to latest.
    add-to-path: false          # Optional: don't add lokalise2 command to PATH (it's installed under the `./bin` directory)

- name: Download translations
  # Or use ./bin/lokalise2 if you choose not to add lokalise2 to PATH
  run: |
    lokalise2 file download --token API_TOKEN --project-id abcd1234.5678 --format json
```

## Parameters

- `target-version` *(optional)* — Version of the Lokalise CLI to install. Use the version number only (e.g., `3.1.1`), and do not include the `v` prefix. If not provided, the latest available version will be installed.
- `force-install` *(optional, default: `false`)* — Reinstall Lokalise CLI even if it is already installed.
- `add-to-path` *(optional, default: `true`)* — Add the Lokalise CLI installation directory to the `PATH` environment variable for subsequent workflow steps.
  + By default, the CLI is installed to the `./bin` directory within the workspace.

## License

Apache license v2.0. Ilya Bodrov-Krukowski and Lokalise group.
