export PROJECT ?= $(shell basename $(shell pwd))

-include $(shell curl -sSL -o .tronador "https://cowk.io/acc"; echo .tronador)
## Runs make within charts/$(PROJECT) directory for Helm Chart Versioning
version/helm: packages/install/gitversion
	@$(MAKE) -C charts/$(PROJECT) tag

## Node Version Bump and creates VERSION File
version: packages/install/gitversion
	$(call assert-set,GITVERSION)
	@echo "$(shell $(GITVERSION) -output json -showvariable SemVer)" > VERSION
	@mvn --batch-mode versions:set -DnewVersion=$(shell $(GITVERSION) -output json -showvariable SemVer)


## Charts initialization for Node Project
charts/init:
	@cp -r charts/node charts/$(PROJECT)
ifeq ($(OS),darwin)
	@sed -i '' -e "s/^name: .*$$/name: $(PROJECT)/g" charts/$(PROJECT)/Chart.yaml
else ifeq ($(OS),linux)
	@sed -i -e "s/^name: .*$$/name: $(PROJECT)/g" charts/$(PROJECT)/Chart.yaml
endif