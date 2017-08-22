pyang --ietf --strict --max-line-length=70 -p ../../voucher/ ../ietf-voucher-request\@*.yang
pyang --canonical -p ../../voucher/ ../ietf-voucher-request\@*.yang
yanglint -p ../../voucher/ ../ietf-voucher-request\@*.yang

echo "Testing ex-file-voucher-request.json..."
yanglint -p ../../voucher/ -s ../ietf-voucher-request\@*.yang ex-file-voucher-request.json


