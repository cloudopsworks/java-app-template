# Value comes from Github vars.HELM_REGISTRY_ADDRESS
CHART_REPO_URL := $(HELM_REGISTRY_ADDRESS)
# Value comes from Github vars.DOCKER_REGISTRY_ADDRESS
DOCKER_REGISTRY := $(DOCKER_REGISTRY_ADDRESS)
CHART_REPO := $(REPOSITORY_OWNER)
CURRENT=$(pwd)
NAME := $(REPOSITORY_NAME)
OS := $(shell uname)
PREVIEW_VERSION := $(shell cat ../../VERSION)
PREVIEW_NAME := $(PR_NAME)
NS := $(shell kubectl get ns | grep $(NAME)-$(PREVIEW_NAME))
PREVIEW_DOMAIN := $(PREVIEW_DOMAIN_NAME)

create-namespace:
ifndef NS
	kubectl create ns $(NAME)-$(PREVIEW_NAME)
endif

check-release:
REL := $(shell helm list --namespace $(NAME)-$(PREVIEW_NAME) | grep preview | wc -l)

preview: create-namespace check-release
ifeq ($(OS),Darwin)
	sed -i "" -e "s/version:.*/version: $(PREVIEW_VERSION)/" Chart.yaml
	sed -i "" -e "s/version:.*/version: $(PREVIEW_VERSION)/" ../*/Chart.yaml
	sed -i "" -e "s|repository:.*|repository: $(DOCKER_REGISTRY)/$(CHART_REPO)/$(NAME)|" values.yaml
	sed -i "" -e "s/tag:.*/tag: $(PREVIEW_VERSION)/" values.yaml
else ifeq ($(OS),Linux)
	sed -i -e "s/version:.*/version: $(PREVIEW_VERSION)/" Chart.yaml
	sed -i -e "s/version:.*/version: $(PREVIEW_VERSION)/" ../*/Chart.yaml
	sed -i -e "s|repository:.*|repository: $(DOCKER_REGISTRY)/$(CHART_REPO)/$(NAME)|" values.yaml
	sed -i -e "s/tag:.*/tag: $(PREVIEW_VERSION)/" values.yaml
else
	echo "platfrom $(OS) not supported to release from"
	exit -1
endif
	echo "  version: $(PREVIEW_VERSION)" >> requirements.yaml
	rm -rf requirements.lock
	helm dependency build
	helm lint
ifeq ($(REL),0)
	helm install --namespace $(NAME)-$(PREVIEW_NAME) --set "preview.ingress.host=$(NAME)-$(PREVIEW_NAME).$(PREVIEW_DOMAIN)" preview . 
else
	helm upgrade --namespace $(NAME)-$(PREVIEW_NAME) --set "preview.ingress.host=$(NAME)-$(PREVIEW_NAME).$(PREVIEW_DOMAIN)" preview . 
endif

clean-preview: check-release
ifneq ($(REL),0)
	helm delete --purge preview
	kubectl delete ns $(NAME)-$(PREVIEW_NAME)
endif
