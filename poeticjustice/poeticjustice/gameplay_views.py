import os
import sys
import time
import copy
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
from sqlalchemy import or_, desc
from  sqlalchemy.sql.expression import func

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
    print 'remove_user_friend called', request
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
                            user_name=request.params['user_name'] if 'user_name' in request.params else 'N/A')
                    friend = _save_user(friend, session)

                UxU = ~UserXUser
                uxu = session.query(UxU).filter(UxU.friend_id==friend.id).\
                    filter(UxU.user_id==user.id).first()

                if (uxu is None):
                    uxu = session.query(UxU).filter(UxU.user_id==friend.id).\
                    filter(UxU.friend_id==user.id).first()

                if (uxu is None):
                    # creating a new friendship
                    print 'attempting new friendship'
                    uxu = UserXUser(user_id=user.id, friend_id=friend.id, approved=False)
                    uxu.save(session=session)
                else:
                    # relationship already exists so approve it
                    print 'approving friendship ', uxu.id
                    uxu.approved = True
                    session.add(uxu)
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
    name='user-friends',
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
            filter(U.id!=user.id).\
            filter(UxU.user_id==user.id):
            friends.append({'friend_id':uxu.friend_id, 'approved':uxu.approved,
                'email_address':u.email_address, 'user_name':u.user_name, 'src':'me'})

    # others who have invited me
    with SQLAlchemySessionFactory() as session:
        U, UxU = ~User, ~UserXUser
        for u, uxu in session.query(U, UxU).\
            filter(UxU.friend_id==user.id).\
            filter(U.id!=user.id).\
            filter(UxU.user_id==U.id):
            friends.append({'friend_id':uxu.user_id, 'approved':uxu.approved,
                'email_address':u.email_address, 'user_name':u.user_name, 'src':'them'})

    return {"results":friends}


def get_verse(verseId, userId):
    lines = list()
    last_user_id = None
    next_user_id = None
    owner_id = None
    if verseId:
        with SQLAlchemySessionFactory() as session:
            V, LxV = ~Verse, ~LineXVerse
            for l in session.query(LxV).filter(LxV.verse_id==verseId).order_by(LxV.id):
                lines.append(l.line_text)
                last_user_id = l.user_id

            if (last_user_id):
                # get the next user that is allowed
                verse = session.query(V).filter(V.id==verseId).first()
                owner_id = verse.owner_id
                found = False
                for u in verse.user_ids:
                    if found:
                        next_user_id = u
                        break
                    if last_user_id==u:
                        found = True
            else:
                next_user_id = userId

    print 'returning verse results', lines

    return {"results":{"lines":lines, "next_user_id":next_user_id, "verse_id":verseId, "owner_id":owner_id}}


@view_config(
    name='active-topics',
    request_method='GET',
    context='poeticjustice:contexts.Users',
    renderer='json')
def get_active_topics(request):
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
            print 'loading active topics for user', user.id
            with SQLAlchemySessionFactory() as session:
                topics = []

                V, T, U, UxU= ~Verse, ~VerseCategoryTopic, ~User, ~UserXUser

                # global open verses and topics that are not mine
                for r in session.query(V, T, U).filter(V.verse_category_topic_id==T.id).\
                    filter(V.complete==False).\
                    filter(V.owner_id==U.id).\
                    filter(U.id!=user.id).\
                    filter(V.friends_only==False).\
                    filter(V.participant_count<V.max_participants).\
                    order_by(func.random()).\
                    limit(5):
                    topics.append({"verse_id":r[0].id, "topic_id":r[1].id, "email_address":r[2].email_address,
                        "user_name":r[2].user_name, "src":'world', "next_user_id":r[0].next_user_id, "user_ids":r[0].user_ids})

                # topics that are mine
                for r in session.query(V, T, U).filter(V.verse_category_topic_id==T.id).\
                    filter(V.complete==False).\
                    filter(V.owner_id==U.id).\
                    filter(U.id==user.id).\
                    order_by(func.random()):\
                    # limit(5):
                    topics.append({"verse_id":r[0].id, "topic_id":r[1].id, "email_address":r[2].email_address,
                        "user_name":r[2].user_name, "src":'mine', "next_user_id":r[0].next_user_id, "user_ids":r[0].user_ids})

                # friendship initiated by me
                for r in session.query(V, T, U, UxU).filter(V.verse_category_topic_id==T.id).\
                    filter(V.owner_id==UxU.friend_id).\
                    filter(UxU.user_id==user.id).\
                    filter(V.owner_id==U.id).\
                    filter(UxU.approved==True).\
                    filter(V.complete==False).\
                    filter(V.friends_only==True).\
                    filter(V.participant_count<V.max_participants).\
                    order_by(func.random()).\
                    limit(3):
                    topics.append({"verse_id":r[0].id, "topic_id":r[1].id, "email_address":r[2].email_address,
                        "user_name":r[2].user_name, "src":'friend', "next_user_id":r[0].next_user_id, "user_ids":r[0].user_ids})

                # friendship initiated by friend
                for r in session.query(V, T, U, UxU).filter(V.verse_category_topic_id==T.id).\
                    filter(V.owner_id==UxU.user_id).\
                    filter(UxU.friend_id==user.id).\
                    filter(V.owner_id==U.id).\
                    filter(UxU.approved==True).\
                    filter(V.complete==False).\
                    filter(V.friends_only==True).\
                    filter(V.participant_count<V.max_participants).\
                    order_by(func.random()).\
                    limit(3):
                    topics.append({"verse_id":r[0].id, "topic_id":r[1].id, "email_address":r[2].email_address,
                        "user_name":r[2].user_name, "src":'friend', "next_user_id":r[0].next_user_id, "user_ids":r[0].user_ids})

                return {"results":topics}

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

# TODO: memoize this
@view_config(
    name='get-topics',
    request_method='GET',
    context='poeticjustice:contexts.Users',
    renderer='json')
def get_topics(request):
    try:
        print 'saving new line for verse'
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

            with SQLAlchemySessionFactory() as session:
                topics = []

                T = ~VerseCategoryTopic

                # see if the user is associated to a verse for this topic
                # change the limit later
                for t in session.query(T).order_by(T.id).limit(16):
                    topics.append({"id":t.id, "name":t.name, "min_points_req":t.min_points_req, 
                        "score_modifier":t.score_modifier, "main_icon_name":t.main_icon_name,
                        "verse_category_type_id":t.verse_category_type_id})

                return {"results":topics}

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
    name='active-verse',
    request_method='POST',
    context='poeticjustice:contexts.Users',
    renderer='json')
def get_user_active_verses(request):
    try:
        print 'saving new line for verse'
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

            verseId = request.params['verse_id']
            
            return get_verse(verseId, user.id)

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
    name='verse',
    request_method='POST',
    context='poeticjustice:contexts.Verses',
    renderer='json')
def verse(request):
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

            verseId = request.params['id']
            
            return get_verse(id, user.id)

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
    name='save-line',
    request_method='POST',
    context='poeticjustice:contexts.Users',
    renderer='json')
def save_verse_line(request):
    try:
        print 'saving new line for verse'
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

            # mandatory fields every time
            line = request.params["line"]
            verseId = request.params["verse_id"]
            scoreIncrement = request.params["score_increment"]

            with SQLAlchemySessionFactory() as session:

                verse = session.query(~Verse).filter((~Verse).id==verseId).first()

                # if it's not the first line, update the previous line score for the line
                # and user
                lxv = session.query(~LineXVerse).filter((~LineXVerse).verse_id==verse.id).\
                    order_by(desc((~LineXVerse).id)).first()

                if lxv:
                    lxv.line_score = lxv.line_score + int(scoreIncrement)
                    lxv = LineXVerse(entity=session.merge(lxv))
                    lxv.save(session=session)

                    lastUser = session.query(~User).filter((~User).id==lxv.user_id).first()
                    lastUser.user_score = lastUser.user_score + int(scoreIncrement)
                    lastUser = User(entity=session.merge(lastUser))
                    lastUser.save(session=session)

                # finally, save this users line
                linexverse = LineXVerse(user_id=user.id, verse_id=verse.id, line_text=line, line_score=0)
                linexverse.save(session=session)

                return get_verse(verse.id, user.id)

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
    name='game-state',
    request_method='GET',
    context='poeticjustice:contexts.Users',
    renderer='json')
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


@view_config(
    name='users',
    request_method='GET',
    context='poeticjustice:contexts.Verses',
    renderer='json',
    permission='edit')
def get_verse_users(request):
    print 'get_verse_users called', request
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
                v = Verse.load(int(kwds['id']), session=session)

                if v:
                    rp = (session.query(U)
                            .filter(U.id.in_(v.user_ids))
                            ).all()

                    verse_users = [
                        User(entity=row).to_dict(
                            ignore_fields=[
                                'auth_hash', 'access_token', 'password',
                                'device_rec', 'user_prefs', 'user_types'
                            ]
                        ) for row in rp
                    ]

            return dict(
                verse_users=verse_users,
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
    name='join',
    request_method='POST',
    context='poeticjustice:contexts.Verses',
    renderer='json',
    permission='edit')
def join_verse(request):
    print 'join_verse called', request
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
                v = Verse.load(int(kwds['id']), session=session)
                
                if v.friends_only:
                    if user.id not in v.user_ids:
                        raise HTTPUnauthorized

                if v.participant_count >= v.max_participants:
                    raise HTTPConflict

                is_next = False

                user_ids = copy.deepcopy(v.user_ids)
                user_ids.append(user.id)
                v.participant_count += 1
                setattr(v, 'user_ids', user_ids)
                v.save(session)

                if v.next_user_id == user_ids[0]:
                    # if the next player is the first player
                    # let the new player go first
                    v.next_user_id == user.id
                    is_next = True

                v.max_lines = len(user_ids) * 4

                v.save(session)

            res = dict(
                is_next=is_next,
                verse=v.to_dict(),
                logged_in=auth_usrid,
                user=user.to_dict()
            )
            print res
            return res

        raise HTTPUnauthorized

    except HTTPGone: raise
    except HTTPFound: raise
    except HTTPUnauthorized: raise
    except HTTPConflict: raise
    except HTTPUnauthorized: raise
    except:
        print traceback.format_exc()
        log.exception(traceback.format_exc())
        raise HTTPBadRequest(explanation='Invalid query parameters?')
    finally:
        try:
            session.close()
        except:
            pass















