# this makefile generates the other formats of certificates and examples from some
# base files that come from debug traces of production code.
# the private keys provided here are not in production!!

EXAMPLE1=00-D0-E5-F2-00-02
ALL=idevid_${EXAMPLE1}.asn1.txt idevid_${EXAMPLE1}.cert
ALL+=vr_${EXAMPLE1}.pkcs vr_${EXAMPLE1}.asn1.txt vr_${EXAMPLE1}.json
ALL+=parboiled_vr_${EXAMPLE1}.pkcs parboiled_vr_${EXAMPLE1}.asn1.txt parboiled_vr_${EXAMPLE1}.json
ALL+=voucher_${EXAMPLE1}.pkcs voucher_${EXAMPLE1}.asn1.txt voucher_${EXAMPLE1}.json
ALL+=vendor.cert masa.cert
ALL+=ownerca_secp384r1.cert jrc_prime256v1.cert

all: ${ALL}

idevid_${EXAMPLE1}.asn1.txt: idevid_${EXAMPLE1}.crt
	openssl asn1parse -in idevid_${EXAMPLE1}.crt | fold -60 >idevid_${EXAMPLE1}.asn1.txt

%.cert: %.crt
	openssl x509 -text -in $< >$@

%.pkcs: %.b64
	base64 -d <$? | openssl cms -cmsout -inform der -in - -outform pem -out $@ -text

%.asn1.txt: %.pkcs
	openssl asn1parse -inform pem -in $? | cut -c1-72 >$@

%.json: %.pkcs
	openssl cms -verify -noverify -in $? -inform pem | fold -60 > $@

HIGHWAYDIR=/ssw/projects/pandora/highway/spec/files/cert/
FOUNTAINDIR=/ssw/projects/pandora/fountain/spec/files/cert/
ORIGINDIR=/ssw/projects/pandora/reach/spec/files/product/00-D0-E5-F2-00-02
update:
	cp ${HIGHWAYDIR}/vendor_secp384r1.crt vendor.crt
	cp ${HIGHWAYDIR}/vendor_secp384r1.key vendor.key
	cp ${HIGHWAYDIR}/masa_prime256v1.crt  masa.crt
	cp ${HIGHWAYDIR}/masa_prime256v1.key  masa.key
	cp ${FOUNTAINDIR}/ownerca_secp384r1.crt .
	cp ${FOUNTAINDIR}/ownerca_secp384r1.key .
	cp ${FOUNTAINDIR}/jrc_prime256v1.crt .
	cp ${FOUNTAINDIR}/jrc_prime256v1.key .
	cp ${ORIGINDIR}/device.crt idevid_${EXAMPLE1}.crt
	cp ${ORIGINDIR}/key.pem idevid_${EXAMPLE1}.key
	base64 ${ORIGINDIR}/voucher_${EXAMPLE1}.pkcs    >voucher_${EXAMPLE1}.b64
	base64 ${ORIGINDIR}/vr_${EXAMPLE1}.pkcs         >vr_${EXAMPLE1}.b64
	cp ${ORIGINDIR}/parboiled_vr_${EXAMPLE1}.b64    .
	./checkit




