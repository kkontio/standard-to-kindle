# Standard-to-Kindle

A bash script to download and transfer the full [Standard ebooks](https://standardebooks.org) catalog to a Kindle device.

## Installation

The script uses utilities which may or may not come preinstalled in your operating system:
* `awk`
* `curl`
* `openssl`
* `rg`
* `rsync`

On macOS all but ripgrep come preinstalled. To install via [Homebrew](https://brew.sh): `brew install ripgrep`.

## Usage

Invoke the script: `./standard-to-kindle.bash`

## Notes

The full AZW3 catalog from [Standard ebooks](https://standardebooks.org) is, as of writing, some 950MB. Make sure there's enough disk space on your computer, and Kindle.

If the script is interrupted, it will try to pick up where it left off on subsequent runs.

The script does not update or overwrite books previously downloaded and transferred on subsequent runs. Although, it will download and transfer any new books added to the catalog after the previous run.

By default the script expects Kindle to be mounted at `/Volumes/Kindle`, which may not be true for your system, especially when not on macOS. The expected mount point can be controlled by giving it as a parameter. For example: `./standard-to-kindle.bash /foo/bar/kindle`.
