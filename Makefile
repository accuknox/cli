export CLIOUT=knoxcli
export INC=akutil.sh
export VERSION=v0.2
CLIURL=https://raw.githubusercontent.com/nyrahul/clibash/refs/heads/main/.gen.sh

all:
	@curl -s $(CLIURL) | bash
	./$(CLIOUT) help > README.md
