# this makefile generates the other formats of certificates and examples from some
# base files that come from debug traces of production code.
# the private keys provided here are not in production!!

EXAMPLE1=00-D0-E5-F2-00-02
ALL=idevid_${EXAMPLE1}.asn1.txt idevid_${EXAMPLE1}.txt
ALL+=vr_${EXAMPLE1}.pkcs vr_${EXAMPLE1}.asn1.txt vr_${EXAMPLE1}.json
ALL+=parboiled_vr_${EXAMPLE1}.pkcs parboiled_vr_${EXAMPLE1}.asn1.txt parboiled_vr_${EXAMPLE1}.json
ALL+=voucher_${EXAMPLE1}.pkcs voucher_${EXAMPLE1}.asn1.txt voucher_${EXAMPLE1}.json

all: ${ALL}

# product 00-D0-E5-02-00-20 comes from https://github.com/AnimaGUS-minerva/reach.git/spec/files/product
# it was produced on the MASA called masa.honeydukes.sandelman.ca.
idevid_${EXAMPLE1}.asn1.txt: idevid_${EXAMPLE1}.crt
	openssl asn1parse -in idevid_${EXAMPLE1}.crt >idevid_${EXAMPLE1}.asn1.txt

idevid_${EXAMPLE1}.txt: idevid_${EXAMPLE1}.crt
	openssl x509 -noout -text -in idevid_${EXAMPLE1}.crt >idevid_${EXAMPLE1}.txt

%.pkcs: %.b64
	base64 -d <$? | openssl cms -cmsout -inform der -in - -outform pem -out $@ -text

%.asn1.txt: %.pkcs
	openssl asn1parse -inform pem -in $? | cut -c1-72 >$@

%.json: %.pkcs
	openssl cms -verify -noverify -in $? -inform pem | fold -60 > $@

update:
	cp /ssw/projects/pandora/reach/spec/files/product/${EXAMPLE1}/device.crt idevid_${EXAMPLE1}.crt
	cp /ssw/projects/pandora/reach/spec/files/product/${EXAMPLE1}/key.pem idevid_${EXAMPLE1}.key
	cp /ssw/projects/pandora/reach/spec/files/product/${EXAMPLE1}/voucher_${EXAMPLE1}.b64 voucher_${EXAMPLE1}.b64
	cp /ssw/projects/pandora/reach/spec/files/product/${EXAMPLE1}/vr_${EXAMPLE1}.b64 vr_${EXAMPLE1}.b64
	cp /ssw/projects/pandora/reach/spec/files/product/${EXAMPLE1}/parboiled_vr_${EXAMPLE1}.b64 parboiled_vr_${EXAMPLE1}.b64




