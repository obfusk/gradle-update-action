FROM alpine:3.20
RUN apk add --no-cache bash coreutils curl git grep openjdk17-jdk jq
COPY entrypoint.sh /entrypoint.sh
COPY gradle-update.sh /gradle-update.sh
ENTRYPOINT ["/entrypoint.sh"]
