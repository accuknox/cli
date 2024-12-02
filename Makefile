export CLIOUT=knoxcli
export INC_SH=utils/logo.sh utils/akutil.sh
export VERSION=v0.2
TAG=$(shell git rev-parse --abbrev-ref HEAD)
#CLIURL=http://localhost:8000/cligen.sh
CLIURL=https://raw.githubusercontent.com/nyrahul/clibash/refs/heads/main/cligen.sh

all:
	@curl -s $(CLIURL) | bash
	@./$(CLIOUT) help > README.md && cat utils/usedocker.md >> README.md

build:
	@docker buildx build -t accuknox/$(CLIOUT):$(TAG) .

push: build
	@docker push accuknox/$(CLIOUT):$(TAG)

