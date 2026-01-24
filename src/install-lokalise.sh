#!/bin/bash
set -euo pipefail

FORCE_INSTALL="${FORCE_INSTALL:-false}"
ADD_TO_PATH="${ADD_TO_PATH:-true}"
INSTALLER_URL="https://raw.githubusercontent.com/lokalise/lokalise-cli-2-go/8ba6bbed2637cf615dd97496e99828f92a1817d7/install.sh"
EXPECTED_INSTALLER_SHA="191bd19dae6c810153c925a1787167992bf05871099170870572b3d48f006f6a"

BIN_DIR="${BIN_DIR:-./bin}"
LOKALISE_CLI="$BIN_DIR/lokalise2"

MAX_RETRIES=3
RETRY_DELAY=3

mkdir -p "$BIN_DIR"

INSTALLER_FILE="$(mktemp)"
cleanup() { rm -f "$INSTALLER_FILE"; }
trap cleanup EXIT

sha256_file() {
	local file="$1"

	if command -v sha256sum >/dev/null 2>&1; then
		sha256sum "$file" | awk '{print $1}'
	elif command -v shasum >/dev/null 2>&1; then
		shasum -a 256 "$file" | awk '{print $1}'
	else
		echo "Error: sha256sum/shasum not found; cannot verify installer integrity."
		return 2
	fi
}

download_installer() {
	local attempt=1
	while [[ $attempt -le $MAX_RETRIES ]]; do
		echo "Downloading Lokalise CLI installer (attempt $attempt/$MAX_RETRIES)..."

		if curl -sfLo "$INSTALLER_FILE" "$INSTALLER_URL"; then
			# Basic sanity: non-empty + expected shebang
			if [[ -s "$INSTALLER_FILE" ]]; then
				local first_line
				first_line="$(head -n 1 "$INSTALLER_FILE" || true)"

				if [[ "$first_line" == "#!/bin/sh" ]]; then
					local actual_sha
					if ! actual_sha="$(sha256_file "$INSTALLER_FILE")"; then
						echo "Installer checksum calculation failed."
						exit 1
					fi

					if [[ "${actual_sha,,}" == "${EXPECTED_INSTALLER_SHA,,}" ]]; then
						echo "Installer downloaded and SHA256 verified."
						return 0
					fi

					echo "Installer SHA256 mismatch!"
					echo "Expected: $EXPECTED_INSTALLER_SHA"
					echo "Actual:   $actual_sha"
					echo "First lines of downloaded file:"
					head -n 5 "$INSTALLER_FILE" || true
				else
					echo "Installer validation failed (unexpected shebang: '$first_line')."
					echo "First lines of downloaded file:"
					head -n 5 "$INSTALLER_FILE" || true
				fi
			else
				echo "Installer validation failed (downloaded file is empty)."
			fi

			rm -f "$INSTALLER_FILE"
			INSTALLER_FILE="$(mktemp)"
		else
			echo "Failed to download installer."
		fi

		local delay=$((RETRY_DELAY * attempt))
		echo "Retrying in $delay seconds..."
		sleep "$delay"
		attempt=$((attempt + 1))
	done

	echo "Failed to download a valid Lokalise CLI installer after $MAX_RETRIES attempts."
	exit 1
}

validate_installation() {
	if [[ ! -x "$LOKALISE_CLI" ]]; then
		echo "Error: Lokalise CLI installation failed. '$LOKALISE_CLI' not found or not executable."
		exit 1
	fi

	echo "Lokalise CLI version: $("$LOKALISE_CLI" --version)"
}

add_to_path() {
	if [[ "${ADD_TO_PATH,,}" == "true" ]]; then
		local bin_abs_path
		bin_abs_path="$(cd "$BIN_DIR" && pwd)"

		# for current step
		export PATH="$bin_abs_path:$PATH"

		# for subsequent steps
		if [[ -z "${GITHUB_PATH:-}" ]]; then
			echo "Warning: GITHUB_PATH not set; cannot persist PATH for future steps."
			echo "Add this dir manually if needed: $bin_abs_path"
		else
			echo "Adding $bin_abs_path to PATH for subsequent workflow steps."
			echo "$bin_abs_path" >>"$GITHUB_PATH"
		fi
	fi
}

install_lokalise_cli() {
	download_installer

	local ver="${LOKALISE_CLI_VERSION:-}"
	local tag_arg=""
	if [[ -n "$ver" ]]; then
		ver="${ver#v}"
		tag_arg="v$ver"
		echo "Installing Lokalise CLI version: $tag_arg"
	else
		echo "Installing latest version of Lokalise CLI"
	fi

	if [[ -n "$tag_arg" ]]; then
		bash "$INSTALLER_FILE" -b "$BIN_DIR" "$tag_arg"
	else
		bash "$INSTALLER_FILE" -b "$BIN_DIR"
	fi

	echo "Lokalise CLI installed successfully."
	validate_installation
	add_to_path
}

if [[ "${FORCE_INSTALL,,}" == "true" ]]; then
	echo "Force install enabled. Proceeding with installation."
	install_lokalise_cli
elif [[ ! -x "$LOKALISE_CLI" ]]; then
	install_lokalise_cli
else
	echo "Lokalise CLI is already installed at $LOKALISE_CLI, skipping installation."
	add_to_path
fi
