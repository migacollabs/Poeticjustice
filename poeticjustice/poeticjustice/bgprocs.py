import os
import sys
import time
import shutil
import traceback
import datetime
import multiprocessing
import threading
import PIL as pil
from boto.s3.key import Key
from boto.s3.connection import S3Connection, Location
from pyaella import dinj, MsgChannelNames
from pyaella.server.processes import UploadProcess
from pyaella.tasks import TaskListProctorFactory, Task
from pyaella.orm.xsqlalchemy import SQLAlchemySessionFactory
from poeticjustice.models import *

#  Boto tutorial here http://docs.pythonboto.org/en/latest/s3_tut.html

__all__ = [
    'PoeticJusticeBkgProcessThread'
]


class PoeticJusticeBkgProcessThread(threading.Thread):
    """ """
    AsyncFamily = 'Threading'

    def setup(self):
        print 'PoeticJusticeBkgProcessThread setup called'
        self._task_list, self._task_list_lock = TaskListProctorFactory()()
        self._sssn_fctry = SQLAlchemySessionFactory()
        self._current_session = self._sssn_fctry.Session
        self._app_config = dinj.AppConfig()
        self._dinj_config = get_dinj_config(self._app_config)
        self._dispatch = {
            'BkgProcess_CloseVerseAddToHistory':self.close_verse_add_to_history,
        }

        self._autl_lut = LutValues(model=AssetUsageTypeLookup)

        if not self._app_config.AssetDepot.startswith("s3://"):
            if not os.path.exists(self._app_config.AssetDepot):
                try:
                    os.makedirs(self._app_config.AssetDepot)
                except:pass

        self._lock = threading.RLock()

        self._r_srv = None
        self._pubsub = None
        if('RedisServer' in self._dinj_config.Resources or 'REDISCLOUD_URL' in os.environ):
            if 'REDISCLOUD_URL' in os.environ:
                url = urlparse.urlparse(os.environ.get('REDISCLOUD_URL'))
                self._r_srv = redis.Redis(
                    host=url.hostname, port=url.port, password=url.password)
            elif self._dinj_config.Resources.RedisServer not in [None, '']:
                self._r_srv = redis.Redis(self._dinj_config.Resources.RedisServer)
            self._pubsub = self._r_srv.pubsub()
            self._pubsub.subscribe([MsgChannelNames.TaskEvents])

        self._go = threading.Event()

    def on_new(self, task):
        return self._dispatch[task.Target](task)


    def close_verse_add_to_history(self, task):
        print task

    def shutdown(self):
        self._go.set()

    def run(self):
        print 'MividioBkgProcessThread.run() called'
        self.setup()
        sleep_x = .2
        to_close = set()
        while not self._go.is_set():
            if self._r_srv and self._pubsub:
                if self._pubsub:
                    pass
                    #for item in self._pubsub.listen():
                    #   print 'Message item', item

                item = self._r_srv.rpoplpush(
                    MsgChannelNames.TaskForBackgroundProcessing, 
                    MsgChannelNames.TaskInBackgroundProcessing)

                if item:
                    with self._lock:
                        try:
                            self.on_new(Task ** item)
                        except:
                            print traceback.format_exc()

                time.sleep(sleep_x)

            else:
                try:
                    if len(to_close) > 0:
                        with self._lock:
                            try:
                                for i in range(0,10):
                                    t = to_close.pop()
                                    with self._task_list_lock:
                                        self._task_list.ask_close(t)
                            except:
                                pass
                except:
                    pass
                
                time.sleep(sleep_x)
                task = None
                with self._task_list_lock:
                    task = self._task_list.ask_get()
                if task:
                    sleep_x = .1
                    with self._lock:
                        if self.on_new(task):
                            to_close.add(task)
                else:
                    sleep_x = .5











