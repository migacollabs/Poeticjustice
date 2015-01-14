import os
import sys
import time
import traceback
from optparse import OptionParser
from pyaella.express import *


if __name__ == '__main__':

    app_name = sys.argv[1]
    root_dir = twk_standard_title_caps(app_name)
    app_dir = app_name.lower()
    if not os.path.exists(root_dir):
        os.makedirs(root_dir)
    if not os.path.exists(os.path.join(root_dir, app_dir)):
        os.makedirs(os.path.join(root_dir, app_dir))




