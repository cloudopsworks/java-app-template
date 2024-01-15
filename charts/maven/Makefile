# Value comes from Github vars.HELM_REGISTRY_ADDRESS
CHART_REPO_URL := $(HELM_REGISTRY_ADDRESS)
# Value comes from Github vars.DOCKER_REGISTRY_ADDRESS
DOCKER_REGISTRY := $(DOCKER_REGISTRY_ADDRESS)
CHART_REPO := helm/$(REPOSITORY_OWNER)
CURRENT=$(pwd)
NAME := $(REPOSITORY_NAME)
OS := $(shell uname)
RELEASE_VERSION ?= $(shell cat ../../VERSION)

build: clean
	rm -rf requirements.lock
	helm dependency build
	helm lint

install: clean build
	helm install . --name ${NAME}

upgrade: clean build
	helm upgrade ${NAME} .

delete:
	helm delete --purge ${NAME}

clean:
	rm -rf charts
	rm -rf ${NAME}*.tgz

release: clean
	helm dependency build
	helm lint
	helm package . --app-version $(RELEASE_VERSION)
	@echo "$(HELM_CREDS_PASSWORD)" | helm registry login $(CHART_REPO_URL) --username $(HELM_CREDS_USER) --password-stdin
	helm push $(NAME)-$(RELEASE_VERSION).tgz oci://$(CHART_REPO_URL)/$(CHART_REPO)

tag:
ifeq ($(OS),Darwin)
	sed -i "" -e "s/version:.*/version: $(RELEASE_VERSION)/" Chart.yaml
	sed -i "" -e "s/appVersion:.*/appVersion: $(RELEASE_VERSION)/" Chart.yaml
	sed -i "" -e "s|repository:.*|repository: $(DOCKER_REGISTRY)\/$(REPOSITORY_OWNER)\/$(REPOSITORY_NAME)|" values.yaml
	sed -i "" -e "s/tag:.*/tag: $(RELEASE_VERSION)/" values.yaml
else ifeq ($(OS),Linux)
	sed -i -e "s/version:.*/version: $(RELEASE_VERSION)/" Chart.yaml
	sed -i -e "s/appVersion:.*/appVersion: $(RELEASE_VERSION)/" Chart.yaml
	sed -i -e "s|repository:.*|repository: $(DOCKER_REGISTRY)\/$(REPOSITORY_OWNER)\/$(REPOSITORY_NAME)|" values.yaml
	sed -i -e "s/tag:.*/tag: $(RELEASE_VERSION)/" values.yaml
else
	echo "platfrom $(OS) not supported to release from"
	exit -1
endif
