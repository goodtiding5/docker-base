FROM alpine:latest AS build

ENV GOSU_VERSION 1.11
RUN set -eux; \
	\
	apk add --no-cache --virtual .gosu-deps \
		ca-certificates \
		dpkg \
		gnupg \
	; \
	\
	dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')"; \
	wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch"; \
	wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc"; \
	\
# verify the signature
	export GNUPGHOME="$(mktemp -d)"; \
	gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4; \
	gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu; \
	command -v gpgconf && gpgconf --kill all || :; \
	rm -rf "$GNUPGHOME" /usr/local/bin/gosu.asc; \
	\
# clean up fetch dependencies
	apk del --no-network .gosu-deps; \
	\
	chmod +x /usr/local/bin/gosu; \
# verify that the binary works
	gosu --version; \
	gosu nobody true

FROM alpine:latest
MAINTAINER Kenneth Zhao <ken@epenguin.com>

ARG  DF_UID=1000
ARG  DF_GID=1000
ARG  DF_USER=demo
ARG  DF_GROUP=demo
ARG  DF_HOME=/data

ENV  AS_UID=${DF_UID}
ENV  AS_GID=${DF_GID}
ENV  AS_USER=${DF_USER}
ENV  AS_GROUP=${DF_GROUP}
ENV  AS_HOME=${DF_HOME}

COPY --from=build /usr/local/bin/gosu /usr/local/bin/gosu
COPY ./config /

RUN  apk add --no-cache \
     shadow musl-utils tini \
&&   groupadd -g ${AS_GID} ${AS_GROUP} \
&&   useradd -u ${AS_UID} -g ${AS_GROUP} -d ${AS_HOME} -s /bin/sh -m ${AS_USER}

VOLUME ${AS_HOME}
WORKDIR ${AS_HOME}

ENTRYPOINT ["/sbin/tini", "--", "/entrypoint.sh"]
CMD ["/bin/sh"]
