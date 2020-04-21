#!/bin/sh
tmp=/tmp/attach_$$.tmp
file=$1
subject=$2
to=$3
base=$(basename $file)
BOUNDARY="_====SCI.MAIL.SUB====$$====_"
echo "To: $to" > $tmp
echo "From: dsiroot" >> $tmp
echo "Subject: $subject" >> $tmp
echo "Content-Type: multipart/mixed; boundary=$BOUNDARY" >> $tmp
echo "Mime-Version: 1.0" >> $tmp
#echo "" >> $tmp
#echo "This is a multi-part message in MIME format." >> $tmp
echo "" >> $tmp
echo "--$BOUNDARY" >> $tmp
echo "Content-Type: text/plain; charset=ISO-8859-1" >> $tmp
echo "" >> $tmp
echo "Please find your report attached" >> $tmp
echo "" >> $tmp
echo "--$BOUNDARY" >> $tmp
echo "Content-Transfer-Encoding: base64" >> $tmp
echo "Content-Type: application/octet-stream; name=$base" >> $tmp
echo "Content-Disposition: attachment; filename=$base" >> $tmp
echo "" >> $tmp

openssl base64 < $file >> $tmp
echo "--$BOUNDARY--" >> $tmp
sendmail -oi -t < $tmp
rm $tmp
