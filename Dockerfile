FROM alpine:3.19
RUN apk add --no-cache bash coreutils curl git grep openjdk17-jre-headless jq
COPY entrypoint.sh /entrypoint.sh
COPY gradle-update.sh /gradle-update.sh
ENTRYPOINT ["/entrypoint.sh"]
