import yaml
import glob
import os.path
from src.exception import WowException
from src.config_format import ConfigFormat
from src.platform import Platform


class Config:
    config = {}
    config_file = 'wow.yml'
    platform = ''

    config_format = ConfigFormat()
    config_format.validate_presence_of(['name', 'version', 'files'])
    config_format.validate_with('name', '^[a-z0-9_-]+$', 'Error in config file. Name should'
                                                         ' only contain lowercase, numbers and _-')

    def load(self):
        """
            Load the config file
        """

        if not os.path.isfile(self.config_file):
            raise WowException("Config file does `%s` not exist" % self.config_file)

        stream = open(self.config_file, 'r')
        self.config = yaml.load(stream)
        self.validate()

        if not self.config['platforms'] is None:
            for config_platform in self.config['platforms']:
                if Platform.is_in_platform(config_platform, self.platform):
                    print('In %s' % config_platform)
                else:
                    print('Not %s' % config_platform)

    def validate(self):
        """
            Check the required values where specified
        """
        self.config_format.validate(self.config)

    def all_files(self):
        """
            return all the files matching the patterns provided in the config
        """
        filenames = []

        for pattern in self.config['files']:
            filenames += glob.glob(pattern)
        filenames.append(self.config_file)
        return filenames