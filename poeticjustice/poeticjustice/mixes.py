import os
import sys
import redis
import urlparse
import jsonpickle
import traceback
from hashlib import sha512
from pyramid.httpexceptions import *
from pyaella import memoize, memoize_exp, Mix, MsgChannelNames
from pyaella.orm.xsqlalchemy import SQLAlchemySessionFactory
from pyaella.codify import IdCoder, generate_auth_code
from pyaella.server.api import retrieve_lut_values, filter_model_attrs
from pyaella.server.api import EntityRestorable, EntityNotFound, EntityFound
from pyaella.tasks import *
from pyaella import dinj
from pyaella import op
from pyaella import express

_models = None

@memoize
def _get_model(name):
    global _models
    if not _models:
        _models = SQLAlchemySessionFactory().ModelsModule
    return _models.__dict__[name]


@memoize_exp(expiration=60*5)
def _get_dinj_config(app_config):
    if app_config.FullConfigPath not in [None, '']:
        return dinj.DinjLexicon(parsable=app_config.FullConfigPath)
    raise Exception('No FullConfigPath')




class UserMix(Mix):
    """ mix to add business object methods to the User model"""
    pass

    def post_pre_hook(self, **kwds):
        pass

    def put_pre_hook(self, **kwds):

        if 'id' in kwds and 'current_session_user_id' in kwds:
            if kwds['id'] != kwds['current_session_user_id']:
                raise HTTPUnauthorized

