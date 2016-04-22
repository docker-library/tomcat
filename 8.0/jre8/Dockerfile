FROM java:8-jre

ENV CATALINA_HOME /usr/local/tomcat
ENV PATH $CATALINA_HOME/bin:$PATH
RUN mkdir -p "$CATALINA_HOME"
WORKDIR $CATALINA_HOME

# runtime dependency for Tomcat Native Libraries
RUN apt-get update && apt-get install -y libapr1 && rm -rf /var/lib/apt/lists/*

# see https://www.apache.org/dist/tomcat/tomcat-8/KEYS
RUN set -ex \
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
	done

ENV TOMCAT_MAJOR 8
ENV TOMCAT_VERSION 8.0.33
ENV TOMCAT_TGZ_URL https://www.apache.org/dist/tomcat/tomcat-$TOMCAT_MAJOR/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz

# Tomcat Native 1.2+ requires a newer version of OpenSSL than debian:jessie has available (1.0.2g+)
# see http://tomcat.10.x6.nabble.com/VOTE-Release-Apache-Tomcat-8-0-32-tp5046007p5046024.html (and following discussion)

RUN set -x \
	\
	&& curl -fSL "$TOMCAT_TGZ_URL" -o tomcat.tar.gz \
	&& curl -fSL "$TOMCAT_TGZ_URL.asc" -o tomcat.tar.gz.asc \
	&& gpg --batch --verify tomcat.tar.gz.asc tomcat.tar.gz \
	&& tar -xvf tomcat.tar.gz --strip-components=1 \
	&& rm bin/*.bat \
	&& rm tomcat.tar.gz* \
	\
	&& nativeBuildDir="$(mktemp -d)" \
	&& tar -xvf bin/tomcat-native.tar.gz -C "$nativeBuildDir" --strip-components=1 \
	&& nativeBuildDeps=" \
		gcc \
		libapr1-dev \
		libssl-dev \
		make \
		openjdk-${JAVA_VERSION%%[-~bu]*}-jdk=$JAVA_DEBIAN_VERSION \
	" \
	&& apt-get update && apt-get install -y --no-install-recommends $nativeBuildDeps && rm -rf /var/lib/apt/lists/* \
	&& ( \
		export CATALINA_HOME="$PWD" \
		&& cd "$nativeBuildDir/native" \
		&& [ "$(openssl version | cut -d' ' -f2)" = '1.0.1k' ] \
# http://tomcat.10.x6.nabble.com/VOTE-Release-Apache-Tomcat-8-0-32-tp5046007p5048274.html (ie, HACK HACK HACK)
		&& cp src/sslcontext.c src/sslcontext.c.orig \
		&& awk ' \
				/^    eckey = EC_KEY_new_by_curve_name/ { print "    EC_KEY *eckey = NULL;" } \
				{ print } \
			' src/sslcontext.c.orig > src/sslcontext.c \
		&& ./configure \
			--libdir=/usr/lib/jni \
			--prefix="$CATALINA_HOME" \
			--with-apr=/usr/bin/apr-1-config \
			--with-java-home="$(docker-java-home)" \
			--with-ssl=yes \
		&& make -j$(nproc) \
		&& make install \
	) \
	&& apt-get purge -y --auto-remove $nativeBuildDeps \
	&& rm -rf "$nativeBuildDir" \
	&& rm bin/tomcat-native.tar.gz

# verify Tomcat Native is working properly
RUN set -e \
	&& nativeLines="$(catalina.sh configtest 2>&1)" \
	&& nativeLines="$(echo "$nativeLines" | grep 'Apache Tomcat Native')" \
	&& nativeLines="$(echo "$nativeLines" | sort -u)" \
	&& if ! echo "$nativeLines" | grep 'INFO: Loaded APR based Apache Tomcat Native library' >&2; then \
		echo >&2 "$nativeLines"; \
		exit 1; \
	fi

EXPOSE 8080
CMD ["catalina.sh", "run"]
