VERSION=$(shell ./getver ${DRAFT}.xml )

YANGDATE=$(shell date +%Y-%m-%d)
DRAFT=dtbootstrap-anima-keyinfra
VRDATE=ietf-voucher-request@${YANGDATE}.yang
EXTRA_FILES+=ietf-voucher-request-tree.txt
EXTRA_FILES+=ietf-voucher-request@${YANGDATE}.yang
EXTRA_FILES+=time-sequence-diagram.txt
EXTRA_FILES+=component-diagram.txt
EXTRA_FILES+=examples/jrc_prime256v1.txt
EXTRA_FILES+=examples/jrc_prime256v1.crt
EXTRA_FILES+=examples/jrc_prime256v1.key
EXTRA_FILES+=examples/vr_00-D0-E5-F2-00-02.pkcs
EXTRA_FILES+=examples/vr_00-D0-E5-F2-00-02.asn1.txt
EXTRA_FILES+=examples/vr_00-D0-E5-F2-00-02.json
EXTRA_FILES+=examples/parboiled_vr-00-D0-E5-F2-00-02.pkcs
EXTRA_FILES+=examples/parboiled_vr-00-D0-E5-F2-00-02.asn1.txt
EXTRA_FILES+=examples/parboiled_vr-00-D0-E5-F2-00-02.json
EXTRA_FILES+=examples/voucher_00-D0-E5-F2-00-02.pkcs
EXTRA_FILES+=examples/voucher_00-D0-E5-F2-00-02.asn1.txt
EXTRA_FILES+=examples/voucher_00-D0-E5-F2-00-02.json
EXTRA_FILES+=examples/idevid_00-D0-E5-F2-00-02.crt
EXTRA_FILES+=examples/idevid_00-D0-E5-F2-00-02.txt
EXTRA_FILES+=examples/idevid_00-D0-E5-F2-00-02.asn1.txt
EXTRA_FILES+=examples/idevid_00-D0-E5-F2-00-02.key

${DRAFT}-${VERSION}.txt: ${DRAFT}.txt ${DRAFT}.html
	cp ${DRAFT}.txt ${DRAFT}-${VERSION}.txt
	: git add ${DRAFT}-${VERSION}.txt ${DRAFT}.txt
	cp ${DRAFT}.html ${DRAFT}-${VERSION}.html
	@echo Consider a \'git add\' of html version

ietf-voucher-request-tree.txt: ${VRDATE}
	pyang --path=../voucher -f tree --tree-print-groupings ${VRDATE} > ietf-voucher-request-tree.txt

${VRDATE}: ietf-voucher-request.yang
	sed -e"s/YYYY-MM-DD/${YANGDATE}/" ietf-voucher-request.yang > ${VRDATE}

examples/%.txt: examples/%.crt
	openssl x509 -noout -text -in $? | fold -w 60 >$@

examples/%.asn1.txt: examples/%.pkcs
	base64 -d <$? |	openssl asn1parse -inform der -in - | fold -w 60 >$@

examples/%.asn1.txt: examples/%.crt
	openssl asn1parse -in $? | fold -w 60 >$@

examples/%.json: examples/%.pkcs
	base64 -d <$? | openssl cms -verify -inform der -in - -nosigs -noverify | fold -w 60 >$@

ALL-${DRAFT}.xml: ${DRAFT}.xml ${EXTRA_FILES}
	cat ${DRAFT}.xml | ./insert-figures > ALL-${DRAFT}.xml

%.txt: ALL-%.xml
	@echo PROCESSING: $(subst ALL-,,$@)
	unset DISPLAY; XML_LIBRARY=$(XML_LIBRARY):./src xml2rfc --text -o $(subst ALL-,,$@) $?

%.html: ALL-%.xml
	unset DISPLAY; XML_LIBRARY=$(XML_LIBRARY):./src xml2rfc --html -o $(subst ALL-,,$@) $?

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
.PRECIOUS: ietf-voucher-request@${YANGDATE}.yang
.PRECIOUS: ALL-${DRAFT}.xml
.PRECIOUS: DATE-${DRAFT}.xml

version:
	echo Version: ${VERSION}
