# this file expects the full set of variables ("env.version" + "env.variant")

include "from"
;
def major:
	env.version | split(".")[0]
;
def is_supported_java_version(java):
	# http://tomcat.apache.org/whichversion.html  ("Supported Java Versions")
	(env.version | tonumber) as $version
	| if $version >= 11.0 then
		java >= 17
	elif $version >= 10.1 then
		java >= 11
	else # $version >= 9.0
		java >= 8
	end
;
def is_alpine:
	vendor_variant | contains("alpine")
;
def variant_is_al2: # NOT al20XX
	contains("al2") and (contains("al20") | not)
;
def is_yum:
	vendor_variant | (
		variant_is_al2
		or contains("oraclelinux7")
	)
;
def variant_is_microdnf:
	contains("oraclelinux") or contains("ubi")
;
def is_apt:
	vendor_variant | (
		variant_is_microdnf
		or contains("al2")
		or contains("alpine")
	) | not
;
def is_native_ge_2:
	# https://github.com/apache/tomcat-native/commit/f7930fa16f095717cfc641a8d24e60c343765adc
	# https://github.com/docker-library/tomcat/pull/272
	(env.version | tonumber) as $version
	| $version >= 10.1
;
def has_openssl_ge_3(variant):
	# https://github.com/apache/tomcat-native/commit/f7930fa16f095717cfc641a8d24e60c343765adc
	variant | (
		# amazonlinux
		variant_is_al2 # corretto
		# oraclelinux
		or contains("oraclelinux7") # openjdk
		or contains("oraclelinux8") # openjdk
	) | not
;
