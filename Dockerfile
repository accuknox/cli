FROM alpine:3.14
RUN apk add --no-cache bash curl jq
WORKDIR /home/accuknox
COPY knoxcli .
ENTRYPOINT ["/home/accuknox/knoxcli"]
