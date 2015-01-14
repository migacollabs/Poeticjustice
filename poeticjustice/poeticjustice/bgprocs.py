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
from pyaella import dinj
from pyaella.server.processes import UploadProcess
from pyaella.tasks import TaskListProctorFactory
from pyaella.orm.xsqlalchemy import SQLAlchemySessionFactory
from poeticjustice.models import *

#  Boto tutorial here http://docs.pythonboto.org/en/latest/s3_tut.html

__all__ = [
    'PoeticjusticeUploadProcess',
    'PoeticjusticeUploadThread'
]

class PoeticjusticeUploadProcess(UploadProcess):
    """ """
    AsyncFamily = 'Processing'

    def setup(self):
        self._task_list, self._task_list_lock = TaskListProctorFactory()()
        self._sssn_fctry = SQLAlchemySessionFactory()
        self._app_config = dinj.AppConfig()

    def on_new(self, task):
        pass

class PoeticjusticeUploadThread(threading.Thread):
    """ """
    AsyncFamily = 'Threading'

    def setup(self):
        self._task_list, self._task_list_lock = TaskListProctorFactory()()
        self._sssn_fctry = SQLAlchemySessionFactory()
        self._current_session = self._sssn_fctry.Session
        self._app_config = dinj.AppConfig()
        self._dispatch = {
            'UploadProcess_Image':self.on_new_image,
            'UploadProcess_Video':self.on_new_video
        }
        if not os.path.exists(self._app_config.AssetDepot):
            try:
                os.makedirs(self._app_config.AssetDepot)
            except:pass

        self._lock = threading.RLock()

    def on_new(self, task):
        return self._dispatch[task.Target](task)

    def on_new_image(self, task):
        """
            Pillow (PIL fork) could be used to 
            make thumbnails easier and more
            configurable
        """
        try:
            start = datetime.datetime.now()
            img = pil.Image.open(task.filepath)
            w, h = img.size
            _, ext = os.path.splitext(task.filepath)
            
            db_start = datetime.datetime.now()
            
            if self._current_session == None:
                self._current_session = self._sssn_fctry.Session
                
            asset = Asset(
                name=task.name,
                description=task.description,
                asset_name=task.asset_name,
                height=h, 
                width=w,  
                extention=ext[1:], 
                owner_id=task.owner_id)

            # save Asset
            asset.save(session=self._current_session)
            asset_id = asset.id

            new_path = ''
            
            if self._app_config.AssetDepot.startswith("s3://"):
                bucket_name = self._app_config.AssetDepot[5:]
                conn = S3Connection(
                    os.environ.get('AWS_ACCESS_KEY_ID'),
                    os.environ.get('AWS_SECRET_ACCESS_KEY')
                )
                asset_depot = conn.get_bucket(bucket_name)
                asset_depot_key = Key(asset_depot)
                new_path = task.access_token + '/' + str(asset.id)+ext
                asset_depot_key.key = new_path
                asset_depot_key.set_contents_from_filename(task.filepath)
            else:
                new_path = os.path.join(
                    self._app_config.AssetDepot,
                    task.access_token,
                    str(asset.id)+ext
                    )
                if not os.path.exists(os.path.dirname(new_path)):
                    try:
                        os.makedirs(os.path.dirname(new_path))
                    except:pass

                shutil.copy2(task.filepath, new_path)

            # Do something with new Asset, add to DB, etc..
            os.remove(task.filepath)
            
            return True

        except:
            print traceback.format_exc()
            try:
                self._current_session.close()
                time.sleep(2)
            except:
                pass
            return False

    def on_new_video(self, task):
        _, ext = os.path.splitext(task.filepath)
        sess = self._sssn_fctry.Session
        try:
            asset = Asset(
                name=task.name,
                description=task.description,
                asset_name=task.asset_name,
                height=0, 
                width=0,  
                extention=ext[1:], 
                owner_id=task.owner_id)
            asset.save(session=sess)
            asset_id = asset.id
            new_path = os.path.join(
                self._app_config.AssetDepot,
                task.access_token,
                str(asset.id)+ext
                )
            if not os.path.exists(os.path.dirname(new_path)):
                try:
                    os.makedirs(os.path.dirname(new_path))
                except:pass
            
            shutil.copy2(task.filepath, new_path)

            # Do something with new Asset, add to DB, etc..
            os.remove(task.filepath)
            
            return True

        except:
            print traceback.format_exc()
            return False
    
    def run(self):
        self.setup()
        sleep_x = 1
        to_close = set()
        while 1:
            try:
                if len(to_close) > 0:
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
                sleep_x = 1
                if self.on_new(task):
                    to_close.add(task)
            else:
                sleep_x = 2

