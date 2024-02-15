export PROJECT ?= $(shell basename $(shell pwd))
TRONADOR_AUTO_INIT := true

-include $(shell curl -sSL -o .tronador "https://cowk.io/acc"; echo .tronador)

## Runs make within charts/$(PROJECT) directory for Helm Chart Versioning
helm/version: packages/install/gitversion
	@$(MAKE) -C charts/$(PROJECT) tag

## Runs make within charts/$(PROJECT) directory to execute the helm release into repository
helm/release:
	@$(MAKE) -C charts/$(PROJECT) release

## Version Bump and creates VERSION File - Uses always the FullSemVer from GitVersion (no need to prepend the 'v').
version: packages/install/gitversion
	$(call assert-set,GITVERSION)
ifeq ($(GIT_IS_TAG),1)
	@echo "$(GIT_TAG)" | sed 's/^v\([0-9]\{1,\}\.[0-9]\{1,\}\.[0-9]\{1,\}\)\(+deploy-.*\)\?$g$/\1/' > VERSION
	@mvn --batch-mode versions:set -DnewVersion=$(shell echo "$(GIT_TAG)" | sed 's/^v//')
else
	# Translates + in version to - for helm/docker compatibility
	@echo "$(shell $(GITVERSION) -output json -showvariable FullSemVer | tr '+' '-')" > VERSION
	@mvn --batch-mode versions:set -DnewVersion=$(shell $(GITVERSION) -output json -showvariable FullSemVer | tr '+' '-')
endif

## Charts initialization for Node Project
charts/init:
	@cp -r charts/maven/ charts/$(PROJECT)
ifeq ($(OS),darwin)
	@sed -i '' -e "s|  repository: file.*$$|  repository: file://../$(PROJECT)|g" charts/preview/requirements.yaml
	@sed -i '' -e "s/^name: .*$$/name: $(PROJECT)/g" charts/$(PROJECT)/Chart.yaml
else ifeq ($(OS),linux)
	@sed -i -e "s|  repository: file.*$$|  repository: file://../$(PROJECT)|g" charts/preview/requirements.yaml
	@sed -i -e "s/^name: .*$$/name: $(PROJECT)/g" charts/$(PROJECT)/Chart.yaml
endif

# Modify pom.xml to change the project name with the $(PROJECT) variable
## Code Initialization for Node Project
code/init: charts/init packages/install/gitversion
	$(call assert-set,GITVERSION)
ifeq ($(OS),darwin)
	@sed -i '' -e "s/<artifactId>.*<\/artifactId>/<artifactId>$(PROJECT)<\/artifactId>/g" pom.xml
	@sed -i '' -e "s/<version>.*<\/version>/<version>$(shell $(GITVERSION) -output json -showvariable SemVer | tr '+' '-')-SNAPSHOT<\/version>/g" pom.xml
else ifeq ($(OS),linux)
	@sed -i -e "s/<artifactId>.*<\/artifactId>/<artifactId>$(PROJECT)<\/artifactId>/g" pom.xml
	@sed -i -e "s/<version>.*<\/version>/<version>$(shell $(GITVERSION) -output json -showvariable SemVer | tr '+' '-')-SNAPSHOT<\/version>/g" pom.xml
endif