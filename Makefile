VERSION=$(shell ./getver ${DRAFT}.xml )

YANGDATE=$(shell date +%Y-%m-%d)
DRAFT=dtbootstrap-anima-keyinfra
VRDATE=ietf-voucher-request@${YANGDATE}.yang

${DRAFT}-${VERSION}.txt: ${DRAFT}.txt ${DRAFT}.html
	cp ${DRAFT}.txt ${DRAFT}-${VERSION}.txt
	: git add ${DRAFT}-${VERSION}.txt ${DRAFT}.txt
	cp ${DRAFT}.html ${DRAFT}-${VERSION}.html
	@echo Consider a \'git add\' of html version

ietf-voucher-request-tree.txt: ${VRDATE}
	pyang --path=../voucher -f tree --tree-print-groupings ${VRDATE} > ietf-voucher-request-tree.txt

${VRDATE}: yang/ietf-voucher-request.yang
	sed -e"s/YYYY-MM-DD/${YANGDATE}/" yang/ietf-voucher-request.yang > ${VRDATE}

ALL-${DRAFT}.xml: ${DRAFT}.xml ietf-voucher-request-tree.txt ietf-voucher-request@${YANGDATE}.yang time-sequence-diagram.txt component-diagram.txt
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
