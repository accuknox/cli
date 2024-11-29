export CLIOUT=knoxcli
export INC_SH=akutil.sh
export VERSION=v0.2
CLIURL=http://localhost:8000/cligen.sh
#CLIURL=https://raw.githubusercontent.com/nyrahul/clibash/refs/heads/main/cligen.sh

all:
	@curl -s $(CLIURL) | bash
	./$(CLIOUT) help > README.md
