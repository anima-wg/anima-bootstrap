VERSION=$(shell ./getver ${DRAFT}.xml )

IETFUSER=mcr+ietf@sandelman.ca
YANGDATE=2018-02-14
DRAFT=dtbootstrap-anima-keyinfra
VRDATE=yang/ietf-voucher-request@${YANGDATE}.yang
MUDDATE=yang/ietf-mud-brski-masaurl-extension@${YANGDATE}.yang
EXTRA_FILES+=ietf-voucher-request-tree.txt
EXTRA_FILES+=${VRDATE} ${MUDDATE}
EXTRA_FILES+=time-sequence-diagram.txt
EXTRA_FILES+=component-diagram.txt
EXTRA_FILES+=examples/jrc_prime256v1.txt
EXTRA_FILES+=examples/jrc_prime256v1.crt
EXTRA_FILES+=examples/jrc_prime256v1.key
EXTRA_FILES+=examples/vr_00-D0-E5-02-00-2D.pkcs
EXTRA_FILES+=examples/vr_00-D0-E5-02-00-2D.asn1.txt
EXTRA_FILES+=examples/vr_00-D0-E5-02-00-2D.json
EXTRA_FILES+=examples/parboiled_vr_00-D0-E5-02-00-2D.pkcs
EXTRA_FILES+=examples/parboiled_vr_00-D0-E5-02-00-2D.asn1.txt
EXTRA_FILES+=examples/parboiled_vr_00-D0-E5-02-00-2D.json
EXTRA_FILES+=examples/voucher_00-D0-E5-02-00-2D.pkcs
EXTRA_FILES+=examples/voucher_00-D0-E5-02-00-2D.asn1.txt
EXTRA_FILES+=examples/voucher_00-D0-E5-02-00-2D.json
EXTRA_FILES+=examples/idevid_00-D0-E5-02-00-2D.crt
EXTRA_FILES+=examples/idevid_00-D0-E5-02-00-2D.txt
EXTRA_FILES+=examples/idevid_00-D0-E5-02-00-2D.asn1.txt
EXTRA_FILES+=examples/idevid_00-D0-E5-02-00-2D.key

${DRAFT}-${VERSION}.txt: ${DRAFT}.txt ${DRAFT}.html
	cp ${DRAFT}.txt ${DRAFT}-${VERSION}.txt
	: git add ${DRAFT}-${VERSION}.txt ${DRAFT}.txt
	cp ${DRAFT}.html ${DRAFT}-${VERSION}.html
	@echo Consider a \'git add\' of html version

ietf-voucher-request-tree.txt: ${VRDATE}
	pyang --path=../voucher -f tree --tree-print-groupings ${VRDATE} > ietf-voucher-request-tree.txt

${VRDATE}: ietf-voucher-request.yang
	sed -e"s/YYYY-MM-DD/${YANGDATE}/" ietf-voucher-request.yang > ${VRDATE}

${MUDDATE}: ietf-mud-brski-masaurl-extension.yang
	sed -e"s/YYYY-MM-DD/${YANGDATE}/" ietf-mud-brski-masaurl-extension.yang > ${MUDDATE}

examples/%.txt: examples/%.crt
	openssl x509 -noout -text -in $? | fold -w 60 >$@

examples/%.asn1.txt: examples/%.pkcs
	base64 --decode <$? |	openssl asn1parse -inform der | fold -w 60 >$@

examples/%.asn1.txt: examples/%.crt
	openssl asn1parse -in $? | fold -w 60 >$@

examples/%.json: examples/%.pkcs
	base64 --decode <$? | openssl cms -verify -inform der -nosigs -noverify | fold -w 60 >$@

ALL-${DRAFT}.xml: ${DRAFT}.xml ${EXTRA_FILES}
	cat ${DRAFT}.xml | ./insert-figures > ALL-${DRAFT}.xml
	xml2rfc --v2v3 ALL-${DRAFT}.xml
	mv ALL-${DRAFT}.v2v3.xml ALL-${DRAFT}.xml

%.txt: ALL-%.xml
	./validate-json >.json-errors || cat .json-errors
	@echo PROCESSING: $(subst ALL-,,$@)
	unset DISPLAY; XML_LIBRARY=$(XML_LIBRARY):./src xml2rfc ${NETWORK} --text -o $(subst ALL-,,$@) $?

%.html: ALL-%.xml
	unset DISPLAY; XML_LIBRARY=$(XML_LIBRARY):./src xml2rfc ${NETWORK} --html -o $(subst ALL-,,$@) $?

submit: ALL-${DRAFT}.xml
	curl -S -F "user=${IETFUSER}" -F "xml=@ALL-${DRAFT}.xml" https://datatracker.ietf.org/api/submit

clean:
	-rm -f ${DRAFT}-${VERSION}.xml ${DRAFT}-${VERSION}.txt
	-rm -f ALL-${DRAFT}-${VERSION}.xml
	-rm -f ALL-${DRAFT}.xml
	-rm -f *~
	-rm -f ietf-voucher-request@*.yang

validate: ${VRDATE}
	pyang --ietf --strict --max-line-length=70 -p ../voucher ${VRDATE}
	pyang --canonical -p ../voucher/ ${VRDATE}
	-yanglint -p ../voucher/ ${VRDATE}

	echo "Testing ex-file-voucher-request.json..."
	-yanglint -p ../../voucher/ -s ${VRDATE} refs/ex-file-voucher-request.json


.PRECIOUS: ${DRAFT}-${VERSION}.xml
.PRECIOUS: ${VRDATE}
.PRECIOUS: ALL-${DRAFT}.xml
.PRECIOUS: DATE-${DRAFT}.xml

version:
	echo Version: ${VERSION}
