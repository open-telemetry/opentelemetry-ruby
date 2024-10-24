# Virtualized python tools via docker

# The directory where the virtual environment is created.
VENVDIR := venv

PYTOOLS := $(VENVDIR)/bin

# The pip executable in the virtual environment.
PIP := $(PYTOOLS)/pip

# The directory in the docker image where the current directory is mounted.
WORKDIR := /workdir

# The python image to use for the virtual environment.
PYTHONIMAGE := python:3.11.3-slim-bullseye

# Run the python image with the current directory mounted.
DOCKERPY := docker run --rm -v "$(CURDIR):$(WORKDIR)" -w $(WORKDIR) $(PYTHONIMAGE)

# Create a virtual environment for Python tools.
$(PYTOOLS):
# The `--upgrade` flag is needed to ensure that the virtual environment is
# created with the latest pip version.
	@$(DOCKERPY) bash -c "python3 -m venv $(VENVDIR) && $(PIP) install --upgrade pip"

# Install python packages into the virtual environment.
$(PYTOOLS)/%: $(PYTOOLS)
	@$(DOCKERPY) $(PIP) install -r requirements.txt

CODESPELL = $(PYTOOLS)/codespell
$(CODESPELL): PACKAGE=codespell

.PHONY: codespell
codespell: $(CODESPELL)
	@$(DOCKERPY) $(CODESPELL)
