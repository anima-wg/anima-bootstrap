#!/bin/sh

# run by MCR to update data from code trees.
cp /corp/projects/pandora/fountain/spec/files/cert/jrc_prime256v1.* examples

cp /corp/projects/pandora/highway/db/devices/00-D0-E5-F2-00-02/device.crt examples/idevid_00-D0-E5-F2-00-02.crt
cp /corp/projects/pandora/highway/db/devices/00-D0-E5-F2-00-02/key.pem examples/idevid_00-D0-E5-F2-00-02.key

fold -w 60 /corp/projects/pandora/fountain/tmp/voucher_request-00-D0-E5-F2-00-02.pkcs      >examples/parboiled_vr-00-D0-E5-F2-00-02.pkcs
fold -w 60 /corp/projects/pandora/reach/tmp/vr_00-D0-E5-F2-00-02.pkcs      >examples/vr_00-D0-E5-F2-00-02.pkcs
fold -w 60 /corp/projects/pandora/reach/tmp/voucher_00-D0-E5-F2-00-02.pkcs >examples/voucher_00-D0-E5-F2-00-02.pkcs

