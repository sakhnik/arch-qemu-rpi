#!/bin/bash

# Edit Znet's IPTV playlist for convenience.

sed_rules='
s/Общеформатные/Загальні/g
s/Новостные/Новинні/g
s/Развлекательные/Розважальні/g
s/Познавательные/Пізнавальні/g
s/Кино/Кіно/g
s/Музыка/Музика/g
s/Детские/Дитячі/g
s/HD каналы/HD канали/g
/ntv_/,+1d
'

curl -sL http://znet.kiev.ua/iptv.m3u8 \
    | sed -e "$sed_rules"
