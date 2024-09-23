export PROJECT ?= $(shell basename $(shell pwd))
TRONADOR_AUTO_INIT := true

GITVERSION ?= $(INSTALL_PATH)/gitversion
GH ?= $(INSTALL_PATH)/gh
YQ ?= $(INSTALL_PATH)/yq

-include $(shell curl -sSL -o .tronador "https://cowk.io/acc"; echo .tronador)

## Version Bump and creates VERSION File - Uses always the FullSemVer from GitVersion (no need to prepend the 'v').
version: packages/install/gitversion
	$(call assert-set,GITVERSION)
ifeq ($(GIT_IS_TAG),1)
	@echo "$(GIT_TAG)" | sed -E 's/^v([0-9]+\.[0-9]+\.[0-9]+((-alpha|-beta).[0-9]?)?)(\+deploy-.*)?$$/\1/g' > VERSION
	@mvn --batch-mode versions:set -DnewVersion=$(shell echo "$(GIT_TAG)" | sed 's/^v//')
else
	# Translates + in version to - for helm/docker compatibility
	@echo "$(shell $(GITVERSION) -output json -showvariable FullSemVer | tr '+' '-')" > VERSION
	@mvn --batch-mode versions:set -DnewVersion=$(shell $(GITVERSION) -output json -showvariable FullSemVer | tr '+' '-')
endif

# Modify pom.xml to change the project name with the $(PROJECT) variable
## Code Initialization for Node Project
code/init: packages/install/gitversion packages/install/gh packages/install/yq
	$(call assert-set,GITVERSION)
	$(call assert-set,GH)
	$(call assert-set,YQ)
	$(eval $@_OWNER := $(shell $(GH) repo view --json 'name,owner' -q '.owner.login'))
	@$(YQ) eval -i '.project.artifactId = "$(PROJECT)"' pom.xml
	@$(YQ) eval -i '.project.version = "$(shell $(GITVERSION) -output json -showvariable MajorMinorPatch | tr '+' '-')-SNAPSHOT"' pom.xml
