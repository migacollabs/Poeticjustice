import os
import sys
import time
import datetime
import traceback
import logging
import ConfigParser
from hashlib import sha512
from pyramid.response import Response
from pyramid.view import view_config, forbidden_view_config
from pyramid.httpexceptions import *
from pyramid.security import (remember, forget, authenticated_userid)
from mako.template import Template
#amazon s3 support
from boto.s3.connection import S3Connection, Location
from boto.s3.key import Key
# pyaella imports
from pyaella import *
from pyaella import dinj
from pyaella.server.api import retrieve_entity, make_result_repr, filter_model_attrs
from pyaella.server.api import _process_subpath, _process_args, _process_xmodel_args
from pyaella.server.api import get_current_user, get_current_rbac_user
from pyaella.orm.xsqlalchemy import SQLAlchemySessionFactory
from pyaella.orm.auth import get_user
from pyaella.geo import GPSPoint
from pyaella.metacode import tmpl as pyaella_templates
from pyaella.server.processes import Emailer
from pyaella.server.api import LutValues

from poeticjustice import default_hashkey
from poeticjustice.models import *


log = logging.getLogger(__name__)
log.setLevel(logging.DEBUG)
fh = logging.FileHandler(__name__+'.log')
fh.setLevel(logging.DEBUG)
frmttr = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
fh.setFormatter(frmttr)
log.addHandler(fh)
log.info('Started')


HOST, PORT = None, None
try:
    # Read host and port from a standard
    # Paste, waitress config .ini file 
    __cfg = ConfigParser.ConfigParser()
    __cfg.read(sys.argv[1])
    HOST = __cfg.get('server:main', 'host')
    PORT = __cfg.get('server:main', 'port')
except:pass # ignore

def get_session():
    return SQLAlchemySessionFactory().Session

# TODO: memoize
def get_app_config():
    return dinj.AppConfig()

def get_dinj_config(app_config):
    return dinj.DinjLexicon(parsable=app_config.FullConfigPath)

@memoize
def get_site_addr():
        sn = get_dinj_config(get_app_config()).Web.SiteName 
        return sn + ':%s'%PORT if PORT not in ['80', ''] else ''


@view_config(
    name='score',
    request_method='POST',
    context='poeticjustice:contexts.UserUpdates',
    renderer='json')
def update_user_score(request):
    print 'update_user_score called', request
    try:
        args = list(request.subpath)
        kwds = _process_subpath(request.subpath, formUrlEncodedParams=request.POST)
        ac = get_app_config()
        dconfig = get_dinj_config(ac)
        auth_usrid = authenticated_userid(request)
        user, user_type_names, user_type_lookup = (
            get_current_rbac_user(auth_usrid,
                accept_user_type_names=[
                    'sys',
                    'player'
                ]
            )
        )
        if user and user.is_active:
            with SQLAlchemySessionFactory() as session:
                user = User(entity=session.merge(user))

                user.user_score += int(kwds['score_increment']) if 'score_increment' in kwds else 0
                user.save(session=session)

            return dict(
                logged_in=auth_usrid,
                user=user.to_dict()
            )

        raise HTTPUnauthorized

    except HTTPGone: raise
    except HTTPFound: raise
    except HTTPUnauthorized: raise
    except HTTPConflict: raise
    except:
        print traceback.format_exc()
        log.exception(traceback.format_exc())
        raise HTTPBadRequest(explanation='Invalid query parameters?')
    finally:
        try:
            session.close()
        except:
            pass


@view_config(
    name='userfriends',
    request_method='GET',
    context='poeticjustice:contexts.Users',
    renderer='json')
def get_user_friends(request):
    print 'get_user_friends called', request
    try:
        args = list(request.subpath)
        kwds = _process_subpath(args)
        auth_usrid = authenticated_userid(request)

        user, user_type_names, user_type_lookup = (
            get_current_rbac_user(auth_usrid,
                accept_user_type_names=[
                    'sys',
                    'player'
                ]
            )
        )
        if user and user.is_active:
            with SQLAlchemySessionFactory() as session:
                user = User(entity=session.merge(user))
                U, UxU = ~User, ~UserXUser
                friends = []
                for u, uxu in session.query(U, UxU).\
                    filter(U.id==UxU.user_id).\
                    filter(U.id==user.id):
                    friends.add({'friend_id':uxu.friend_id, 'approved':uxu.approved,
                        'email_address':u.email_address, 'user_name':u.user_name})

            return friends

        raise HTTPUnauthorized

    except HTTPGone: raise
    except HTTPFound: raise
    except HTTPUnauthorized: raise
    except HTTPConflict: raise
    except:
        print traceback.format_exc()
        log.exception(traceback.format_exc())
        raise HTTPBadRequest(explanation='Invalid query parameters?')
    finally:
        try:
            session.close()
        except:
            pass


@view_config(
    name='random',
    request_method='POST',
    context='poeticjustice:contexts.Topics',
    renderer='json')
def get_random_topics(request):
    print 'get_random_topics called', request
    try:
        args = list(request.subpath)
        kwds = _process_subpath(request.subpath, formUrlEncodedParams=request.POST)
        ac = get_app_config()
        dconfig = get_dinj_config(ac)
        auth_usrid = authenticated_userid(request)
        user, user_type_names, user_type_lookup = (
            get_current_rbac_user(auth_usrid,
                accept_user_type_names=[
                    'sys',
                    'player'
                ]
            )
        )
        if user and user.is_active:
            with SQLAlchemySessionFactory() as session:
                user = User(entity=session.merge(user))

                print kwds['xids']

                exclude_topic_ids = sets()


            return dict(
                logged_in=auth_usrid,
                user=user.to_dict()
            )

        raise HTTPUnauthorized

    except HTTPGone: raise
    except HTTPFound: raise
    except HTTPUnauthorized: raise
    except HTTPConflict: raise
    except:
        print traceback.format_exc()
        log.exception(traceback.format_exc())
        raise HTTPBadRequest(explanation='Invalid query parameters?')
    finally:
        try:
            session.close()
        except:
            pass













