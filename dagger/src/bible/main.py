"""Dagger pipeline for the Dart/Flutter Bible.

Wraps the repo's melos gate so it runs in a container, identical on any Docker
host (bible \u00a72.10). The pipeline is the melos scripts; Dagger only provides the
container they run in.

Run the full gate:

    dagger call verify --source=.
"""

import dagger
from dagger import dag, function, object_type


def _example(source: dagger.Directory) -> dagger.Container:
    """A Dart container with the example package resolved."""
    return (
        dag.container()
        .from_("dart:stable")
        .with_directory("/src", source)
        .with_workdir("/src/example")
        .with_exec(["dart", "pub", "get"])
    )


@object_type
class Bible:
    """The bible's gate, run in a container (format -> analyze -> test)."""

    @function
    async def verify(self, source: dagger.Directory) -> str:
        """Run the whole gate: the `melos run verify` script contract."""
        return await (
            _example(source)
            .with_exec(["dart", "run", "melos", "run", "verify"])
            .stdout()
        )

    @function
    async def analyze(self, source: dagger.Directory) -> str:
        """Run the analyzer gate only (`melos run analyze`)."""
        return await (
            _example(source)
            .with_exec(["dart", "run", "melos", "run", "analyze"])
            .stdout()
        )
