#!/usr/bin/env bash

/bin/sed -e "s/<host>/$MAIL_HOST/" /etc/msmtprc.template |
/bin/sed -e "s/<port>/$MAIL_PORT/" |
/bin/sed -e "s/<user>/$MAIL_USER/" |
/bin/sed -e "s/<from>/$MAIL_FROM/" |
/bin/sed -e "s/<password>/$MAIL_PASS/" > /etc/msmtprc;
