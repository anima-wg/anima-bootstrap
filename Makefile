VERSION=$(shell ./getver ${DRAFT}.xml )

YANGDATE=$(shell date +%Y-%m-%d)
DRAFT=dtbootstrap-anima-keyinfra
VRDATE=ietf-voucher-request@${YANGDATE}.yang

${DRAFT}-${VERSION}.txt: ${DRAFT}.txt
	cp ${DRAFT}.txt ${DRAFT}-${VERSION}.txt
	git add ${DRAFT}-${VERSION}.txt ${DRAFT}.txt

ietf-voucher-request-tree.txt: ietf-voucher-request@${YANGDATE}.yang
	pyang --path=../voucher -f tree --tree-print-groupings ${VRDATE} > ietf-voucher-request-tree.txt

${VRDATE}: ietf-voucher-request.yang
	sed -e"s/YYYY-MM-DD/${YANGDATE}/" ietf-voucher-request.yang > ${VRDATE}

${DRAFT}.xml: ietf-voucher-request-tree.txt
${DRAFT}.xml: ietf-voucher-request@${YANGDATE}.yang

ALL-%.xml: %.xml
	cat $? | ./insert-figures >ALL-$?

%.txt: ALL-%.xml
	@echo PROCESSING: $(subst ALL-,,$@)
	unset DISPLAY; XML_LIBRARY=$(XML_LIBRARY):./src xml2rfc --text -o $(subst ALL-,,$@) $?

%.html: ALL-%.xml
	unset DISPLAY; XML_LIBRARY=$(XML_LIBRARY):./src xml2rfc --html -o $(subst ALL-,,$@) $?

clean:
	-rm -f ${DRAFT}-${VERSION}.xml ${DRAFT}-${VERSION}.txt
	-rm -f ALL-${DRAFT}-${VERSION}.xml
	-rm -f *~
	-rm -f ietf-voucher-request@*.yang

validate: ${VRDATE}
	pyang --ietf --strict --max-line-length=70 -p ../voucher ${VRDATE}
	pyang --canonical -p ../voucher/ ${VRDATE}
	-yanglint -p ../voucher/ ${VRDATE}

	echo "Testing ex-file-voucher-request.json..."
	-yanglint -p ../../voucher/ -s ${VRDATE} refs/ex-file-voucher-request.json


.PRECIOUS: ${DRAFT}-${VERSION}.xml ALL-${DRAFT}-${VERSION}.xml
.PRECIOUS: ietf-voucher-request@${YANGDATE}.yang

version:
	echo Version: ${VERSION}
