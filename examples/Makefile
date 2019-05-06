# this makefile generates the other formats of certificates and examples from some
# base files that come from debug traces of production code.
# the private keys provided here are not in production!!

EXAMPLE1=00-D0-E5-02-00-2D
all: idevid_${EXAMPLE1}.asn1.txt idevid_${EXAMPLE1}.txt

# product 00-D0-E5-02-00-20 comes from https://github.com/AnimaGUS-minerva/reach.git/spec/files/product
# it was produced on the MASA called masa.honeydukes.sandelman.ca.
idevid_${EXAMPLE1}.asn1.txt: idevid_${EXAMPLE1}.crt
	openssl asn1parse -in idevid_${EXAMPLE1}.crt >idevid_${EXAMPLE1}.asn1.txt

idevid_${EXAMPLE1}.txt: idevid_${EXAMPLE1}.crt
	openssl x509 -noout -text -in idevid_${EXAMPLE1}.crt >idevid_${EXAMPLE1}.txt

update:
	cp /ssw/projects/pandora/reach/spec/files/product/00-D0-E5-02-00-2D/device.crt idevid_${EXAMPLE1}.crt
	cp /ssw/projects/pandora/reach/spec/files/product/00-D0-E5-02-00-2D/key.pem idevid_${EXAMPLE1}.key





