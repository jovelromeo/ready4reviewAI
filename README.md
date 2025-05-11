# Ready4Review

> This project is a work in progress aimed at transitioning from a traditional Dockerfile-based workflow to using [Dagger](https://dagger.io/) for CI/CD and automation tasks. The current implementation uses a shell script (`entrypoint.sh`) to automate environment setup and secure key handling within a Docker container.

## What `entrypoint.sh` Does
1. Sets up SSH key authentication.
2. Clones the repository.
3. Creates a new branch.
4. Uses Ra-AID to generate changes.
5. Commits and pushes the changes.
6. Creates a pull request.

## Running this project
Just copy the .env.example file to .env and fill in the values. Then run `docker compose up`.