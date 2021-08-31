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
	| if test("^openjdk-") then
		"openjdk:" + java_version + "-" + java_variant + ltrimstr("openjdk")
	elif . == "corretto" and java_variant == "jdk" then
		"amazoncorretto:" + java_version
	elif test("^temurin-") then
		"eclipse-temurin:" + java_version + "-" + java_variant + ltrimstr("temurin")
	else
		error("unknown vendor variant: " + .)
	end
;
