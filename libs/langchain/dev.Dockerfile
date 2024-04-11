# This is a Dockerfile for the Development Container

# Use the Python base image
ARG VARIANT="3.11-bullseye"
FROM mcr.microsoft.com/devcontainers/python:0-${VARIANT} AS langchain-dev-base

USER vscode

# Define the version of Poetry to install (default is 1.4.2)
# Define the directory of python virtual environment
ENV POETRY_HOME=/home/vscode/langchain-py-env \
    POETRY_VERSION=1.7.1 

ENV POETRY_VIRTUALENVS_IN_PROJECT=false \
    POETRY_NO_INTERACTION=true \
    PYTHON_VIRTUALENV_HOME=${POETRY_HOME}/venv

# Create a Python virtual environment for Poetry and install it
RUN curl -sSL https://install.python-poetry.org | python3 -

ENV PATH="$PYTHON_VIRTUALENV_HOME/bin:$PATH" \
    VIRTUAL_ENV=$PYTHON_VIRTUALENV_HOME

# Setup for bash
RUN poetry completions bash >> /home/vscode/.bash_completion && \
    echo "export PATH=$PYTHON_VIRTUALENV_HOME/bin:$PATH" >> ~/.bashrc

# Set the working directory for the app
WORKDIR /workspaces/langchain

# Use a multi-stage build to install dependencies
FROM langchain-dev-base AS langchain-dev-dependencies

ARG PYTHON_VIRTUALENV_HOME

# Copy only the dependency files for installation
COPY libs/langchain/pyproject.toml libs/langchain/poetry.toml libs/langchain/poetry.lock ./

# Copy the langchain library for installation
COPY libs/langchain/ libs/langchain/

# Copy the core library for installation
COPY libs/core ../core

# Copy the community library for installation
COPY libs/community/ ../community/

# Copy the text-splitters library for installation
COPY libs/text-splitters/ ../text-splitters/

# Install the Poetry dependencies (this layer will be cached as long as the dependencies don't change)
RUN poetry install --no-interaction --without codespell \
    && pip install rapidfuzz requests_toolbelt
