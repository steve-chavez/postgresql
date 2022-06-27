## Development

[Nix](https://nixos.org/download.html) is required to set up the environment.

Once you have nix, you can execute the following to get custom scripts to aid in development in a temporary PATH:

```bash
# might take a while in downloading all the dependencies
$ nix-shell
```

All scripts are prefixed with `pg-`.

### Building

For building, execute:

```bash
$ pg-build
```

This will produce a `./build` directory. Incremental builds are enabled with `ccache`.

Executing this command is necessary for the other commands to work.

### Connecting to psql

For connecting to psql on the custom built postgres, execute:

```bash
$ pg-with psql
```

This will start a new data directory on a tmpdir. It's safe to invoke multiple times.

### Testing

You can run the tests with:

```bash
$ pg-test
```

Or:

```bash
$ pg-with make installcheck-parallel
```

### Styling

You can run `pgindent`(on the git changed files) and `pgperltidy` with:

```bash
$ pg-style
```

### Building and serving the docs

You can build and serve the docs on port 5050 with:

```bash
$ pg-serve-docs
```
