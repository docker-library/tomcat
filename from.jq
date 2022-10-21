# this file expects "env.variant" (but has no other dependency)

def java_dir:
	env.variant | split("/")[0] # "jdk16", etc
;
def java_version:
	java_dir | ltrimstr("jre") | ltrimstr("jdk") # "16", etc
;
def java_variant:
	java_dir | rtrimstr(java_version) # "jdk", "jre"
;
def vendor_variant:
	env.variant | split("/")[1] # "openjdk-slim-buster", etc
;
def from:
	vendor_variant
	| if test("^corretto-") then
		"amazoncorretto:" + java_version + ltrimstr("corretto") + "-" + java_variant
	elif test("^openjdk-") then
		"openjdk:" + java_version + "-" + java_variant + ltrimstr("openjdk")
	elif test("^temurin-") then
		"eclipse-temurin:" + java_version + "-" + java_variant + ltrimstr("temurin")
	elif test("^sapmachine") then
		"sapmachine:" + java_version
	else
		error("unknown vendor variant: " + .)
	end
;
