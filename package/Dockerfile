# syntax=docker/dockerfile:1
# The plugin's run-time files as an image at /redmine_serverless, published to
# ghcr.io/redmine-kit/redmine_serverless (.github/workflows/package.yml). A Redmine image
# takes them with:
#   COPY --from=ghcr.io/redmine-kit/redmine_serverless:<tag>@sha256:<digest> /redmine_serverless plugins/redmine_serverless/
# .dockerignore chooses the files; those that do not exist yet are left out.
# Built from the repository root: docker build -f package/Dockerfile .
FROM scratch
LABEL org.opencontainers.image.source=https://github.com/redmine-kit/redmine_serverless \
  org.opencontainers.image.description="The Redmine plugin redmine_serverless: run-time files" \
  org.opencontainers.image.licenses=GPL-2.0-or-later
COPY . /redmine_serverless/
