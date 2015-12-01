# coding=utf-8
import re
import os
from bakgen.core import constants

from constants import SEPARATOR, TECHNOLOGIES


class ReadGroup(object):
    def __init__(self):
        self.data_files = []
        self.technology_info = ''
        self.is_reads_pair = False
        self.template_size = []
        self.segment_placement = ''


class CheckResult(object):
    def __init__(self, is_success, message, emails):
        self.emails = emails
        self.message = message
        self.is_success = is_success

    def __str__(self):
        return 'Is success: %s, message: %s' % (str(self.is_success), self.message)


def parse_delete_comments(input_string):
    template_email = re.compile('\s*#.*@.*\n')
    email_info = re.findall(template_email, input_string)
    template_comment = re.compile('\s*#.*\n')
    output_string = template_comment.sub('', input_string)
    template_empty_string = re.compile('\n\n')

    result_emails = []
    for each_email in email_info:
        result_emails.append(re.sub('[\n\s#]', '', each_email))

    output_string = template_empty_string.sub('', output_string)
    return [output_string, result_emails]


def check_file(file_path):
    template_groups = re.compile('(?<!^)readgroup *= *')
    get_data_expression = re.compile('(data *= *)(.*)')
    get_technology_expression = re.compile('(technology *= *)(.*)')
    get_template_size = re.compile('(template_size *= *)(.*)')
    template_separator = re.compile(r'(?<!^)%s*(?!$)' % SEPARATOR)

    with open(file_path, 'r') as f:
        file_content = f.read()

    [file_content_without_comments, emails] = parse_delete_comments(file_content)

    separate_reads_info = re.split(template_groups, file_content_without_comments)
    if '\n' in separate_reads_info:
        separate_reads_info.remove('\n')

    num_groups = len(separate_reads_info)

    if num_groups < 1:
        result = CheckResult(is_success=False,
                             message=u"File contains no info about any read group", emails=emails)
        constants.logger.error(result)
        return result

    reads = []
    for reads_str in separate_reads_info:
        read_group = ReadGroup()

        if len(re.findall(get_data_expression, reads_str)) * len(
                re.findall(get_technology_expression, reads_str)) == 0:
            result = CheckResult(is_success=False,
                                 message=u"Required fields not found in read group description: data; technology",
                                 emails=emails)
            constants.logger.error(result)
            return result

        data_files_group = re.findall(get_data_expression, reads_str)[0][1]
        data_files = re.split(template_separator, data_files_group)
        read_group.data_files = data_files

        for data_file in data_files:
            if not os.path.exists(data_file):
                result = CheckResult(is_success=False,
                                     message=u"Data file %s not found" % data_file, emails=emails)
                constants.logger.error(result)
                return result

        technology = re.findall(get_technology_expression, reads_str)[0][1]
        read_group.technology_info = technology

        if technology not in TECHNOLOGIES:
            result = CheckResult(is_success=False,
                                 message=u"Technology not allowed: %s, allowed technologies: %s" % (
                                     technology, str(TECHNOLOGIES)), emails=emails)
            constants.logger.error(result)
            return result

        template_size_group = re.findall(get_template_size, reads_str)
        if len(template_size_group) != 0:
            read_group.is_reads_pair = True

            template_size = re.split(template_separator, template_size_group[0][1])
            is_numbers = re.match('^[\d ]*$', template_size_group[0][1])
            if len(template_size) != 2 or not is_numbers:
                result = CheckResult(is_success=False,
                                     message=u"'template_size' should contain two integer numbers",
                                     emails=emails)
                constants.logger.error(result)
                return result
            read_group.template_size = template_size
        reads.append(read_group)

    result = CheckResult(is_success=True, message=u'File %s is alright' % file_path, emails=emails)
    constants.logger.info(result)
    return result
