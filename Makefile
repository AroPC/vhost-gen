ifneq (,)
.error This Makefile requires GNU Make.
endif

# -------------------------------------------------------------------------------------------------
# Default configuration
# -------------------------------------------------------------------------------------------------
.PHONY: help lint pycodestyle pydocstyle black dist sdist bdist build checkbuild deploy autoformat clean


VERSION = 2.7
BINPATH = bin/
BINNAME = vhost-gen

CONFIG = conf.yml
TPLDIR = templates


# -------------------------------------------------------------------------------------------------
# Default Target
# -------------------------------------------------------------------------------------------------
help:
	@echo "lint             Lint source code"
	@echo "test             Test source code"
	@echo "autoformat       Autoformat code according to Python black"
	@echo "install          Install (requires sudo or root)"
	@echo "uninstall        Uninstall (requires sudo or root)"
	@echo "build            Build Python package"
	@echo "dist             Create source and binary distribution"
	@echo "sdist            Create source distribution"
	@echo "bdist            Create binary distribution"
	@echo "clean            Build"


# -------------------------------------------------------------------------------------------------
# Lint Targets
# -------------------------------------------------------------------------------------------------

lint: pycodestyle pydocstyle black mypy

.PHONY: pycodestyle
pycodestyle:
	@echo "# -------------------------------------------------------------------- #"
	@echo "# Check pycodestyle"
	@echo "# -------------------------------------------------------------------- #"
	docker run --rm $$(tty -s && echo "-it" || echo) -v $(PWD):/data cytopia/pycodestyle --show-source --show-pep8 $(BINPATH)$(BINNAME)

.PHONY: pydocstyle
pydocstyle:
	@echo "# -------------------------------------------------------------------- #"
	@echo "# Check pydocstyle"
	@echo "# -------------------------------------------------------------------- #"
	docker run --rm $$(tty -s && echo "-it" || echo) -v $(PWD):/data cytopia/pydocstyle $(BINPATH)$(BINNAME)

.PHONY: black
black:
	@echo "# -------------------------------------------------------------------- #"
	@echo "# Check black"
	@echo "# -------------------------------------------------------------------- #"
	docker run --rm $$(tty -s && echo "-it" || echo) -v ${PWD}:/data cytopia/black -l 100 --check --diff $(BINPATH)$(BINNAME)

.PHONY: mypy
mypy:
	@echo "# -------------------------------------------------------------------- #"
	@echo "# Check mypy"
	@echo "# -------------------------------------------------------------------- #"
	docker run --rm $$(tty -s && echo "-it" || echo) -v ${PWD}:/data cytopia/mypy --config-file setup.cfg $(BINPATH)$(BINNAME)


# -------------------------------------------------------------------------------------------------
# Test Targets
# -------------------------------------------------------------------------------------------------

test:
	@$(MAKE) --no-print-directory _test FILE=check-errors-normal.sh
	@$(MAKE) --no-print-directory _test FILE=check-errors-reverse.sh
	@$(MAKE) --no-print-directory _test FILE=check-errors-template-normal.sh
	@$(MAKE) --no-print-directory _test FILE=check-errors-template-reverse.sh


_test:
	@echo "--------------------------------------------------------------------------------"
	@echo " Test $(FILE)"
	@echo "--------------------------------------------------------------------------------"
	docker run \
		--rm \
		$$(tty -s && echo "-it" || echo) \
		-v $(PWD):/data \
		-w /data \
		python:$(VERSION)-alpine \
		sh -c "pip install -r requirements.txt \
			&& apk add bash make \
			&& make install \
			&& tests/$(FILE)"


# -------------------------------------------------------------------------------------------------
# Build Targets
# -------------------------------------------------------------------------------------------------

dist: sdist bdist

sdist:
	docker run \
		--rm \
		$$(tty -s && echo "-it" || echo) \
		-v $(PWD):/data \
		-w /data \
		-u $$(id -u):$$(id -g) \
		python:$(VERSION)-alpine \
		python setup.py sdist

bdist:
	docker run \
		--rm \
		$$(tty -s && echo "-it" || echo) \
		-v $(PWD):/data \
		-w /data \
		-u $$(id -u):$$(id -g) \
		python:$(VERSION)-alpine \
		python setup.py bdist_wheel --universal

build:
	docker run \
		--rm \
		$$(tty -s && echo "-it" || echo) \
		-v $(PWD):/data \
		-w /data \
		-u $$(id -u):$$(id -g) \
		python:$(VERSION)-alpine \
		python setup.py build

checkbuild:
	docker run \
		--rm \
		$$(tty -s && echo "-it" || echo) \
		-v $(PWD):/data \
		-w /data \
		python:$(VERSION)-alpine \
		sh -c "pip install twine \
		&& twine check dist/*"


# -------------------------------------------------------------------------------------------------
# Publish Targets
# -------------------------------------------------------------------------------------------------

deploy:
	docker run \
		--rm \
		$$(tty -s && echo "-it" || echo) \
		-v $(PWD):/data \
		-w /data \
		python:$(VERSION)-alpine \
		sh -c "pip install twine \
		&& twine upload dist/*"


# -------------------------------------------------------------------------------------------------
# Misc Targets
# -------------------------------------------------------------------------------------------------

autoformat:
	docker run \
		--rm \
		$$(tty -s && echo "-it" || echo) \
		-v $(PWD):/data \
		-w /data \
		cytopia/black -l 100 $(BINPATH)$(BINNAME)
clean:
	-rm -rf $(BINNAME).egg-info/
	-rm -rf dist/
	-rm -rf build/

install:
	@echo "Installing files"
	@echo ""
	@# Create directories
	mkdir -p /etc/vhost-gen
	mkdir -p /etc/vhost-gen/templates
	@# Install binary
	install -m 0755 $(BINPATH)/$(BINNAME) /usr/bin/$(BINNAME)
	@# Install configs
	install -m 0644 etc/$(CONFIG) /etc/vhost-gen/$(CONFIG)
	install -m 0644 etc/$(TPLDIR)/*.yml /etc/vhost-gen/$(TPLDIR)
	@echo "Installation complete:"
	@echo "----------------------------------------------------------------------"
	@echo ""

uninstall:
	@echo "Removing files"
	@echo ""
	rm -r /etc/vhost-gen
	rm /usr/bin/$(BINNAME)
	@echo "Uninstallation complete:"
	@echo "----------------------------------------------------------------------"
	@echo ""
