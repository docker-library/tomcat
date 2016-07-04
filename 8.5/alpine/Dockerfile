#Version: tomcat 8.5.3
#FROM morrowind/alpine-cst8:3.4
FROM java:openjdk-8u92-jre-alpine
MAINTAINER Morro Wind "imorrowind@hotmail.com"

ENV TOMCAT_VERSION 8.5.3

# runtime dependencies for Tomcat Native Libraries
# Tomcat Native 1.2+ requires a newer version of OpenSSL than alpine:3.4 has available (1.0.2g+)
# see http://tomcat.10.x6.nabble.com/VOTE-Release-Apache-Tomcat-8-0-32-tp5046007p5046024.html (and following discussion)
RUN \
	apk add --no-cache --virtual .build-deps \
		gcc \
		libc-dev \
		make \
		openssl-dev \
		curl \
		gnupg \
		apr-dev \
		apr-util-dev \
	&& export CATALINA_HOME=/usr/local/tomcat \
	&& export PATH=$CATALINA_HOME/bin:$PATH \
	&& curl -fSL https://www.apache.org/dist/tomcat/tomcat-8/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz -o tomcat.tar.gz \
	&& curl -fSL https://www.apache.org/dist/tomcat/tomcat-8/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz.asc -o tomcat.tar.gz.asc \
	&& export GNUPGHOME="$(mktemp -d)" \
	&& set -ex \
		&& for key in \
			05AB33110949707C93A279E3D3EFE6B686867BA6 \
			07E48665A34DCAFAE522E5E6266191C37C037D42 \
			47309207D818FFD8DCD3F83F1931D684307A10A5 \
			541FBE7D8F78B25E055DDEE13C370389288584E7 \
			61B832AC2F1C5A90F0F9B00A1C506407564C17A3 \
			79F7026C690BAA50B92CD8B66A3AD3F4F22C4FED \
			9BA44C2621385CB966EBA586F72C284D731FABEE \
			A27677289986DB50844682F8ACB77FC2E86E29AC \
			A9C5DF4D22E99998D9875A5110C01C5A2F6059E7 \
			DCFD35E0BF8CA7344752DE8B6FB21E8933C60243 \
			F3A04C595DB5B6A5F1ECA43E3B7BBB100D811BBE \
			F7DA48BB64BCB84ECBA7EE6935CD23C10D498E23 \
		; do \
			gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
	done \

	&& gpg --batch --verify tomcat.tar.gz.asc tomcat.tar.gz \
	&& rm -r "$GNUPGHOME" tomcat.tar.gz.asc \
	&& tar -xvf tomcat.tar.gz \
	&& mv apache-tomcat-$TOMCAT_VERSION /usr/local/tomcat \
	&& rm tomcat.tar.gz \
	&& cd /usr/local/tomcat \
	&& rm bin/*.bat \
	&& NATIVEBUILDDIR="$(mktemp -d)" \
	&& tar -xf bin/tomcat-native.tar.gz -C "$NATIVEBUILDDIR" \
	&& CONFIG=" \
		--libdir=/usr/lib \
		--prefix=/usr/local/tomcat \
		--with-apr=/usr/bin/apr-1-config \
		--with-java-home=/usr/lib/gcc/x86_64-alpine-linux-musl/5.3.0 \
		--with-ssl=yes \
	" \
	&& ( \
		export CATALINA_HOME="$PWD" \
		&& cd "$NATIVEBUILDDIR/tomcat-native-1.2.7-src/native" \
		&& pwd \
		&& ./configure $CONFIG \
		&& make \
		&& make install \
	) \
	&& cd $CATALINA_HOME \
	&& rm -rf "$NATIVEBUILDDIR" \
	&& rm bin/tomcat-native.tar.gz \
	&& apk del .build-deps \
	&& apk add --no-cache gettext apr \
	&& set -e \
		&& nativeLines="$(catalina.sh configtest 2>&1)" \
		&& nativeLines="$(echo "$nativeLines" | grep 'Apache Tomcat Native')" \
		&& nativeLines="$(echo "$nativeLines" | sort -u)" \
		&& if ! echo "$nativeLines" | grep 'INFO: Loaded APR based Apache Tomcat Native library' >&2; then \
			echo >&2 "$nativeLines"; \
			exit 1; \
		fi 
COPY server.xml /usr/local/tomcat/conf/server.xml

EXPOSE 8080

CMD ["/usr/local/tomcat/bin/catalina.sh", "run"]
