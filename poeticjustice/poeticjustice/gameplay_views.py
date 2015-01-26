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

# sqlalchemy
from sqlalchemy import or_

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
from poeticjustice.views import _save_user


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
    name='removefriend',
    request_method='POST',
    context='poeticjustice:contexts.Users',
    renderer='json')
def remove_user_friend(request):
    print 'add_user_friend called', request
    try:
        auth_usrid = authenticated_userid(request)

        user, user_type_names, user_type_lookup = (
            get_current_rbac_user(auth_usrid,
                accept_user_type_names=[
                    'sys',
                    'player'
                ]
            )
        )

        if user and user.is_active and user.email_address==auth_usrid:

            friendId = request.params['friend_id']

            # check if exists

            with SQLAlchemySessionFactory() as session:

                friend = session.query(~UserXUser).filter(or_((~UserXUser).friend_id==friendId, (~UserXUser).user_id==friendId)).first()
                
                if (friend is not None):
                    session.delete(friend)
                    session.commit()

                return get_friends(user)

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
    name='addfriend',
    request_method='POST',
    context='poeticjustice:contexts.Users',
    renderer='json')
def add_user_friend(request):
    print 'add_user_friend called', request
    try:
        auth_usrid = authenticated_userid(request)

        user, user_type_names, user_type_lookup = (
            get_current_rbac_user(auth_usrid,
                accept_user_type_names=[
                    'sys',
                    'player'
                ]
            )
        )

        if user and user.is_active and user.email_address==auth_usrid:

            friendEmailAddress = request.params['friend_email_address']

            # check if exists

            with SQLAlchemySessionFactory() as session:

                friend = session.query(~User).filter((~User).email_address==friendEmailAddress).first()

                if (friend is None):
                    friend = User(email_address=friendEmailAddress, 
                            user_name=request.params['user_name'] if 'user_name' in request.params else None)
                    friend = _save_user(friend, session)

                uxu = session.query(~UserXUser).filter(or_((~UserXUser).friend_id==friend.id, (~UserXUser).user_id==friend.id)).first()

                if (uxu is None):    
                    uxu = UserXUser(user_id=user.id, friend_id=friend.id, approved=False)
                    uxu.save(session=session)
                else:
                    # relationship already exists so approve it
                    uxu = UserXUser(user_id=user.id, friend_id=friend.id, approved=True, entity=session.merge(uxu))
                    uxu.save(session=session)

                return get_friends(user)

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
        auth_usrid = authenticated_userid(request)

        user, user_type_names, user_type_lookup = (
            get_current_rbac_user(auth_usrid,
                accept_user_type_names=[
                    'sys',
                    'player'
                ]
            )
        )

        if user and user.is_active and user.email_address==auth_usrid:
            return get_friends(user)

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

def get_friends(user):
    friends = []
    # my friends that i explicitly invited
    with SQLAlchemySessionFactory() as session:
        user = User(entity=session.merge(user))
        U, UxU = ~User, ~UserXUser
        for u, uxu in session.query(U, UxU).\
            filter(U.id==UxU.friend_id).\
            filter(UxU.user_id==user.id):
            friends.append({'friend_id':uxu.friend_id, 'approved':uxu.approved,
                'email_address':u.email_address, 'user_name':u.user_name, 'src':'me'})

    # others who have invited me
    with SQLAlchemySessionFactory() as session:
        U, UxU = ~User, ~UserXUser
        for u, uxu in session.query(U, UxU).\
            filter(UxU.friend_id==user.id).\
            filter(UxU.user_id==U.id):
            friends.append({'friend_id':uxu.user_id, 'approved':uxu.approved,
                'email_address':u.email_address, 'user_name':u.user_name, 'src':'them'})

    return {"results":friends}


@view_config(
    name='game-state',
    request_method='GET',
    context='poeticjustice:contexts.Users',
    renderer='json',
    permission='edit')
def get_user_game_state(request):
    print 'get_user_game_state called', request
    try:
        args = list(request.subpath)
        kwds = _process_subpath(request.subpath)
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

                U, V = ~User, ~Verse
                rp = (session.query(U, V)
                        .filter(U.id==user.id)
                        .filter(V.owner_id==U.id)
                        .filter(V.complete==False)
                        ).all()

                tids = set()
                for row in rp: 
                    u, v = row
                    tids.add(v.verse_category_topic_id)

            return dict(
                open_topics=list(tids),
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
    name='start',
    request_method='GET',
    context='poeticjustice:contexts.Users',
    renderer='json',
    permission='edit')
def start_topic(request):
    print 'start_topic called', request
    try:
        args = list(request.subpath)
        kwds = _process_subpath(request.subpath)
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

                U, V = ~User, ~Verse
                rp = (session.query(U, V)
                        .filter(U.id==user.id)
                        .filter(V.owner_id==U.id)
                        .filter(V.complete==False)
                        ).all()

                tids = set()
                for row in rp: 
                    u, v = row
                    tids.add(v.verse_category_topic_id)

            return dict(
                open_topics=list(tids),
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













