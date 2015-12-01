import argparse
import os
import sys
from bakgen.core.send_result import send_mail

sys.dont_write_bytecode = True

parser = argparse.ArgumentParser()
parser.add_argument('-r', action='store', nargs='+', help='Recievers (seperate with space)',
                    required=True)
parser.add_argument('-s', action='store', help='Subject')
parser.add_argument('-b', action='store', help='Body')
parser.add_argument('-f', action='store', nargs='+', help='Files (separate with space)', default=[])

args = parser.parse_args()
receivers = list(args.r)
subject = str(args.s)
body = str(args.b)
files = list(args.f)

send_mail(receivers, subject=subject, body=body, files=files)
