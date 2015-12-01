# coding=utf-8
import argparse
import os
import sys
from bakgen.core.constants import RECEIVERS_INI_PATH
from bakgen.core.send_result import send_mail, get_lines
from bakgen.core.check_file import check_file

sys.dont_write_bytecode = True

parser = argparse.ArgumentParser()
parser.add_argument('file', action='store', help='A file to check')
parser.add_argument('--nomail', action='store_true', help='If exists, no email will be sent')

args = parser.parse_args()

file_path = str(args.file)
nomail = bool(args.nomail)

check_result = check_file(file_path)

receivers_ini_path = os.path.join(sys.path[0], RECEIVERS_INI_PATH)
with open(receivers_ini_path, 'w') as file_receivers:
    map(lambda x: file_receivers.writelines('%s\n' % x), check_result.emails)

if not nomail and not check_result.is_success:
    send_mail(check_result.emails, 'file check result', str(check_result))

if check_result.is_success:
    print 'Файл в порядке'
else:
    print 'Ошибка в файле %s' % file_path