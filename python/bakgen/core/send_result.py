from email import encoders
from email.mime.base import MIMEBase
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
import mimetypes
import os
import smtplib
import constants
from constants import SMTP_PASSWORD, SMTP_LOGIN, SUBJECT_PREFIX, SMTP_SERVER, SMTP_PORT


def get_lines(filename):
    with open(filename) as f:
        lines = f.readlines()

    for i in xrange(0, len(lines)):
        lines[i] = lines[i].strip()

    return lines


def send_mail(receivers, subject, body, files=[]):
    constants.logger.info('start sending email')
    msg = MIMEMultipart()
    msg["From"] = SMTP_LOGIN
    msg["To"] = str(receivers)
    msg["Subject"] = SUBJECT_PREFIX + ' ' + subject

    if len(files) > 0:
        for file_to_attach in files:
            if os.path.isfile(file_to_attach):
                ctype, encoding = mimetypes.guess_type(file_to_attach)
                if ctype is None or encoding is not None:
                    ctype = "application/octet-stream"

                maintype, subtype = ctype.split("/", 1)
                fp = open(file_to_attach, "rb")
                attachment = MIMEBase(maintype, subtype)
                attachment.set_payload(fp.read())
                fp.close()
                encoders.encode_base64(attachment)

                attachment.add_header("Content-Disposition", "attachment", filename=file_to_attach)
                msg.attach(attachment)
            else:
                body = body + "<br/>Can't found file: " + file_to_attach + "<br/>"

    msg.attach(MIMEText(body, 'html'))
    user = SMTP_LOGIN
    pwd = SMTP_PASSWORD
    from_email = SMTP_LOGIN

    try:
        server = smtplib.SMTP(SMTP_SERVER, SMTP_PORT)
        server.ehlo()
        server.starttls()
        server.login(user, pwd)
        server.sendmail(from_email, receivers, msg.as_string())
        server.close()
        constants.logger.info(
            'Successfully sent the mail to \n %s \n' % (str(receivers)))

    except BaseException:
        constants.logger.error(
            "Failed to send the mail")
