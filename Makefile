# if using docker PROJECT should be your username
PROJECT=myproject
NAME=artemis
VERSION=0.1
REGISTRY=`minishift openshift registry`
UPPER_NAME=$(shell echo $(NAME) | tr a-z A-Z))
.PHONY: all build tag_latest release

all: build

build:
#	docker build -t $(PROJECT)/$(NAME):$(VERSION) --rm .
	docker build -t $(NAME):$(VERSION) --rm .

tag_latest:
#	docker tag $(PROJECT)/$(NAME):$(VERSION) $(REGISTRY)/$(PROJECT)/$(NAME):latest
	docker tag $(NAME):$(VERSION) $(REGISTRY)/$(PROJECT)/$(NAME):latest

release: tag_latest
	@if ! docker images $(NAME) | awk '{ print $$2 }' | grep -q -F $(VERSION); then echo "$(NAME) version $(VERSION) is not yet built. Please run 'make build'"; false; fi
	docker push $(REGISTRY)/$(PROJECT)/$(NAME)

deploy_docker:
	docker run -d -p 61616:61616 --name artemis -e ARTEMIS_USERNAME=admin -e ARTEMIS_PASSWORD=smartvm $(PROJECT)/$(NAME)

deploy:
	oc new-app $(REGISTRY)/$(PROJECT)/$(NAME) -e ARTEMIS_USERNAME=admin -e ARTEMIS_PASSWORD=smartvm --name $(NAME) 
	oc expose dc/$(NAME) --port 61616 --type=LoadBalancer --name="$(NAME)-ingress"
	@echo "$(UPPER_NAME)_HOST=`minishift ip`"
	@echo "$(UPPER_NAME)_PORT=`oc get services | sed -n 's/^art.*61616:\([0-9]*\)[/].*$$/\1/p'`"

cleanup:
	oc delete dc/$(NAME) service/$(NAME) route/$(NAME)
	oc delete pods $$(oc get pods | awk '/$(NAME)/ { print $$1}')
	docker rmi -f $$(docker images | awk '/$(NAME)/ { print $$3 }')

# https://github.com/durandom/manageiq-kafka-client/blob/master/collector/Makefile (this file)
# https://github.com/marcelocaj/artemis-hawtio-docker (ui too)
# https://github.com/vromero/activemq-artemis-docker (base image)
