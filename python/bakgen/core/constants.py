import logging
import logging.config
import os
import yaml

path_to_constants = os.path.dirname(os.path.abspath(__file__))
log_config_name = 'log_conf.yaml'
base_logger_name = 'pipeline_logger'


def setup_logging(
        default_path=os.path.join(path_to_constants, log_config_name),
        default_level=logging.INFO,
        env_key='LOG_CFG'):
    path = default_path
    value = os.getenv(env_key, None)
    if value:
        path = value
    if os.path.exists(path):
        with open(path, 'rt') as f:
            string = f.read()
            config = yaml.load(string)
        logging.config.dictConfig(config)
    else:
        logging.basicConfig(level=default_level)


setup_logging()
logger = logging.getLogger(base_logger_name)
SEPARATOR = ' '
TECHNOLOGIES = {'solexa', 'iontor', 'santer', '454'}

# email sending settings
SMTP_SERVER = "smtp.gmail.com"
SMTP_PORT = 587
SMTP_LOGIN = 'bakgen.niifhm@gmail.com'
SMTP_PASSWORD = 'prostosahar'
SUBJECT_PREFIX = '[bakgen]'
RECEIVERS_INI_PATH = 'receivers_tmp.ini'