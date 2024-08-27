export PROJECT ?= $(shell basename $(shell pwd))
TRONADOR_AUTO_INIT := true

GITVERSION ?= $(INSTALL_PATH)/gitversion
GH ?= $(INSTALL_PATH)/gh

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
code/init: charts/init packages/install/gitversion packages/install/gh
	$(call assert-set,GITVERSION)
	$(call assert-set,GH)
	$(eval $@_OWNER := $(shell $(GH) repo view --json 'name,owner' -q '.owner.login'))
ifeq ($(OS),darwin)
	@sed -i '' -e "s/<artifactId>.*<\/artifactId>/<artifactId>$(PROJECT)<\/artifactId>/g" pom.xml
	@sed -i '' -e "s/<version>.*<\/version>/<version>$(shell $(GITVERSION) -output json -showvariable SemVer | tr '+' '-')-SNAPSHOT<\/version>/g" pom.xml
else ifeq ($(OS),linux)
	@sed -i -e "s/<artifactId>.*<\/artifactId>/<artifactId>$(PROJECT)<\/artifactId>/g" pom.xml
	@sed -i -e "s/<version>.*<\/version>/<version>$(shell $(GITVERSION) -output json -showvariable SemVer | tr '+' '-')-SNAPSHOT<\/version>/g" pom.xml
endif