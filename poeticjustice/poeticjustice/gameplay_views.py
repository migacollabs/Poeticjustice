import os
import sys
import time
import copy
import json
import datetime
from collections import OrderedDict
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
from sqlalchemy import or_, desc, and_, not_
from  sqlalchemy.sql.expression import func
from sqlalchemy.orm import aliased

# pyaella imports
from pyaella import *
from pyaella import dinj
from pyaella.codify import IdCoder
from pyaella.server.api import retrieve_entity, make_result_repr, filter_model_attrs
from pyaella.server.api import _process_subpath, _process_args, _process_xmodel_args
from pyaella.server.api import get_current_user, get_current_rbac_user
from pyaella.orm.xsqlalchemy import SQLAlchemySessionFactory
from pyaella.orm.auth import get_user
from pyaella.geo import GPSPoint
from pyaella.metacode import tmpl as pyaella_templates
from pyaella.server.processes import Emailer
from pyaella.server.api import LutValues

from poeticjustice import default_hashkey, idcoder_key
from poeticjustice.models import *
from poeticjustice.views import _save_user


log = logging.getLogger(__name__)
log.setLevel(logging.INFO)
fh = logging.FileHandler(__name__+'.log')
fh.setLevel(logging.DEBUG)
frmttr = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
fh.setFormatter(frmttr)
log.addHandler(fh)
log.info('Started')

IDCODER = IdCoder(kseq=idcoder_key)


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
    name='leave',
    request_method='POST',
    context='poeticjustice:contexts.Users',
    renderer='json')
def leave_verse(request):
    print 'leave_verse called', request
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
                verse_id = kwds['verse_id']

                V = ~Verse
                verse = session.query(V).filter(V.id==verse_id).first()
                
                verse_user_ids = copy.deepcopy(verse.user_ids)
                for i in range(len(verse_user_ids)):
                    if (verse_user_ids[i]==int(user.id)):
                        verse_user_ids[i]=-1

                verse = Verse(entity=session.merge(verse))
                setattr(verse, 'user_ids', verse_user_ids)
                verse.participant_count = verse.participant_count - 1

                verse.save(session)

                open_verse_ids = copy.deepcopy(user.open_verse_ids)
                open_verse_ids.remove(int(verse_id))

                user = User(entity=session.merge(user))
                setattr(user, 'open_verse_ids', open_verse_ids)

                user.save(session)

                return {"results":"ok"}

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
    name='vote',
    request_method='GET',
    context='poeticjustice:contexts.Verses',
    permission='edit',
    renderer='json')
def vote_for_user_line_verse(request):
    print 'vote_for_user_line_verse called', request
    try:
        args = list(request.subpath)
        # kwds = _process_subpath(request.subpath, formUrlEncodedParams=request.POST)
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

                player_id = kwds['pid']
                verse_id = kwds['vid']
                line_id = kwds['lid']

                U, V, LxV = ~User, ~Verse, ~LineXVerse
                rp = (session.query(U, V, LxV)
                        .filter(U.id==player_id)
                        .filter(V.id==verse_id)
                        .filter(LxV.user_id==U.id)
                        .filter(LxV.id==line_id)
                        .filter(LxV.verse_id==V.id)
                        ).first()

                do_add_to_history = False
                if rp:

                    player, verse, lineXverse = rp

                    # mark the fact that this user voted
                    votes_d = json.loads(verse.votes) if verse.votes else {}

                    if not votes_d:
                        votes_d = {}
                    if user.id in votes_d:
                        raise HTTPConflict # this player has already voted
                    votes_d[user.id] = lineXverse.id
                    setattr(verse, 'votes', json.dumps(votes_d))
                    session.add(verse) # commit later

                    # increment lineXverse multiply previous by 2
                    lineXverse.line_score *= 2 if lineXverse.line_score and lineXverse.line_score > 0 else 1
                    session.add(lineXverse)

                    # increment the player's score
                    player.user_score += lineXverse.line_score
                    if not player.num_of_favorited_lines:
                        player.num_of_favorited_lines = 1
                    else:
                        player.num_of_favorited_lines += 1
                    session.add(player)


                    if len(verse.user_ids) == len(votes_d):
                        if not verse.complete:
                            verse.complete = True
                            session.add(verse)
                            do_add_to_history = True
                            print 'verse is complete'

                    session.commit()

                    if do_add_to_history:
                        print 'adding to history'
                        try:
                            verse, jsonable, user_version_history = \
                                close_verse_add_to_history(verse.id, user, session)
                        except:
                            print traceback.format_exc()

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

                return get_friends(user.id, session)

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
                    setattr(uxu, 'approved', True)
                    uxu = UserXUser(entity=session.merge(uxu))
                    uxu.save(session=session)

                return get_friends(user.id, session)

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


def get_user_pref_data(user, key):
    if (user.user_prefs):
        data = json.loads(user.user_prefs)
        if key in data:
            return data[key]
    return {key:None}

# TODO: split this into two and memoize the public one?
@view_config(
    name='leaderboard',
    request_method='GET',
    context='poeticjustice:contexts.Users',
    renderer='json')
def get_leaderboard(request):
    print 'get_leaderboard called', request
    try:
        user_id = None

        if 'user_id' in request.params:
            user_id = request.params['user_id']

        leaderboard_type = request.params["type"]

        users = []
        U = ~User

        with SQLAlchemySessionFactory() as session:

            count = 0

            if leaderboard_type=="Friends":
                # friends
                if user_id:
                    friend_ids = [user_id]
                    for f in get_friends(user_id, session)["results"]:
                        if (f["approved"]==True):
                            friend_ids.append(f["friend_id"])

                    count = 0
                    for r in session.query(U).filter(U.is_active==True).\
                        filter(U.id.in_(friend_ids)).\
                        order_by(desc(U.user_score)):
                        count += 1
                        users.append({"user_name":r.user_name, "user_score":r.user_score, "user_id":r.id,
                            "avatar_name":get_user_pref_data(r, "avatar_name"), "level":r.level, 
                            "num_of_favorited_lines":r.num_of_favorited_lines, "rank":str(count)})
                else:
                    count = 0
                    # this won't happen but just in case...
                    for r in session.query(U).filter(U.is_active==True).\
                        order_by(desc(U.user_score)).limit(25):
                        count += 1
                        users.append({"user_name":r.user_name, "user_score":r.user_score, "user_id":r.id,
                            "avatar_name":get_user_pref_data(r, "avatar_name"), "level":r.level,
                            "num_of_favorited_lines":r.num_of_favorited_lines, "rank":str(count)})
            else:
                # global
                if user_id:
                    count = 0
                    has_user = False
                    for r in session.query(U).filter(U.is_active==True).order_by(desc(U.user_score)).limit(24):
                        count += 1
                        if (r.id==user_id):
                            has_user = True
                        users.append({"user_name":r.user_name, "user_score":r.user_score, "user_id":r.id,
                            "avatar_name":get_user_pref_data(r, "avatar_name"), "level":r.level,
                            "num_of_favorited_lines":r.num_of_favorited_lines, "rank":str(count)})

                    count = 0
                    if has_user==False:
                        for r in session.query(U).filter(U.id==user_id):
                            users.append({"user_name":r.user_name, "user_score":r.user_score, "user_id":r.id,
                            "avatar_name":get_user_pref_data(r, "avatar_name"), "level":r.level,
                            "num_of_favorited_lines":r.num_of_favorited_lines, "rank":"?"})
                else:
                    count = 0
                    for r in session.query(U).filter(U.is_active==True).order_by(desc(U.user_score)).limit(25):
                        count += 1
                        users.append({"user_name":r.user_name, "user_score":r.user_score, "user_id":r.id,
                            "avatar_name":get_user_pref_data(r, "avatar_name"), "level":r.level,
                            "num_of_favorited_lines":r.num_of_favorited_lines, "rank":str(count)})

        return {"results":users}

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

        print 'auth usrid email', auth_usrid

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
                return get_friends(user.id, session)

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

def get_friends(user_id, session):

    friends = []

    # my friends that i explicitly invited
    U, UxU = ~User, ~UserXUser
    MyFriend = aliased(U, name="friend")
    for u, uxu, friend in session.query(U, UxU, MyFriend).\
        filter(U.id==UxU.friend_id).\
        filter(UxU.user_id==user_id).\
        filter(MyFriend.id==U.id):
        friends.append({'friend_id':uxu.friend_id, 'approved':uxu.approved,
            'email_address':u.email_address, 'user_name':u.user_name, 'src':'me',
            'user_score': friend.user_score, 'level':friend.level, 'user_prefs':friend.user_prefs,
            'num_of_favorited_lines':u.num_of_favorited_lines
            })

    # others who have invited me
    for u, uxu, friend in session.query(U, UxU, MyFriend).\
        filter(UxU.user_id==U.id).\
        filter(UxU.friend_id==user_id).\
        filter(MyFriend.id==U.id):
        friends.append({'friend_id':uxu.user_id, 'approved':uxu.approved,
            'email_address':u.email_address, 'user_name':u.user_name, 'src':'them',
            'user_score': friend.user_score, 'level':friend.level, 'user_prefs':friend.user_prefs,
            'num_of_favorited_lines':u.num_of_favorited_lines
            })

    res = {"results":friends}
    return res



def get_verse(verse_id, user_id, session):

    print 'get_verse called', verse_id, user_id

    lines = list()
    lines_d = OrderedDict()
    next_index_user_ids = -1
    owner_id = None
    is_complete = False
    has_all_lines = False
    user_ids = {}
    users = None
    verse = None
    current_user_has_voted = False
    votes_d = {}
    title = ""

    if verse_id:
        verse_id = int(verse_id)

        # V, LxV = ~Verse, ~LineXVerse
        # for l in session.query(LxV).filter(LxV.verse_id==verse_id).order_by(LxV.id):
        #     lines.append(l.line_text)
        #     last_user_id = l.user_id

        U, V, LxV = ~User, ~Verse, ~LineXVerse
        for row in session.query(V, LxV) \
                .filter(V.id==verse_id) \
                .filter(LxV.verse_id==verse_id) \
                .order_by(LxV.id):
            lines.append(row.LineXVerse.line_text)
            lines_d[row.LineXVerse.id] = (row.LineXVerse.user_id, row.LineXVerse.line_text)
            if not verse:
                verse = row.Verse

        if not verse:
            # no verse obj yet, because there are no lines yet
            verse = session.query(V).filter(V.id==verse_id).first()

        owner_id = verse.owner_id
        next_index_user_ids = verse.next_index_user_ids

        # TODO: should check and set complete here?
        is_complete = verse.complete
        user_ids = verse.user_ids
        has_all_lines = len(lines) == verse.participant_count * 4
        title = verse.title

        votes_d = json.loads(verse.votes) if verse.votes else {}
        current_user_has_voted = user_id in votes_d

        # get user data
        sq = (session.query(U.id)
                .filter(U.id.in_(verse.user_ids))
                ).subquery()
        rp = (session.query(U.id, U.user_name, U.user_prefs)
                .filter(U.id.in_(sq))
                ).all()

        # users [(id, email_address, user_prefs jsonable str)]
        # let the client unserialize the json if they need it
        users = [(row[0], row[1], row[2] if row[0] else "") for row in rp]

    else:
        verse_id = -1


    res = dict(
        results=dict(
            lines=lines,
            lines_d=lines_d,
            next_index_user_ids=next_index_user_ids,
            user_ids=user_ids,
            user_data=users,
            votes=votes_d,
            is_complete=is_complete,
            has_all_lines=has_all_lines,
            current_user_has_voted=current_user_has_voted,
            verse_id=verse_id,
            owner_id=owner_id,
            title=title
            )
        )
    print "returning from get_verse", res
    return res




def get_open_topic_keys(topics):
    keys = []
    for k in topics:
        if topics[k]==None:
            keys.append(k)
    return keys


def get_verse_history_ids(user, min_level, session):
    # return all completed verse ids that have been completed
    # for the current level and below
    completed = []
    UVH = ~UserVerseHistory
    for r in session.query(UVH).filter(UVH.player_id==user.id).\
        filter(UVH.level<=min_level):
        completed.append(r.verse_id)
    return completed


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

            friend_ids = []

            with SQLAlchemySessionFactory() as session:

                for f in get_friends(user.id, session)["results"]:
                    if (f["approved"]==True):
                        friend_ids.append(f["friend_id"])
            
                topics = {}

                current_lvl = 16

                if (user.level>1):
                    current_lvl = 16 + ( (user.level-1) * 8)

                # seed topic data for as many topics as necessary
                for i in range(1, (current_lvl+1)):
                    topics[i]=None

                # TODO: need to figure out a way to return fresh new topic/verses when the user
                # levels up - check for verses not in UserVerseHistory
                # only for lower levels...
                verse_history_ids = get_verse_history_ids(user, (user.level-1), session)

                V, T, U, UxU= ~Verse, ~VerseCategoryTopic, ~User, ~UserXUser

                # topics that are mine
                for r in session.query(V, T, U).filter(V.verse_category_topic_id==T.id).\
                    filter(V.owner_id==U.id).\
                    filter(U.id==user.id).\
                    filter(not_(V.id.in_(verse_history_ids))).\
                    filter(T.id.in_(get_open_topic_keys(topics))):

                    votes_d = json.loads(r[0].votes) if r[0].votes else {}
                    current_user_has_voted = str(user.id) in votes_d.keys()

                    topics[r[1].id]={"verse_id":r[0].id, "topic_id":r[1].id, "email_address":r[2].email_address,
                        "user_name":r[2].user_name, "src":'mine', "next_index_user_ids":r[0].next_index_user_ids, 
                        "user_ids":r[0].user_ids, "owner_id":r[0].owner_id, "title":r[0].title,
                        "current_user_has_voted":current_user_has_voted, "complete":r[0].complete,
                        "num_lines":r[0].num_lines
                        }
                
                if user.open_verse_ids:
                    # world or friend open topics that i've joined
                    for r in session.query(V, T, U).\
                        filter(V.verse_category_topic_id==T.id).\
                        filter(U.id==V.owner_id).\
                        filter(U.id!=user.id).\
                        filter(V.id.in_(user.open_verse_ids)).\
                        filter(T.id.in_(get_open_topic_keys(topics))).\
                        filter(not_(V.id.in_(verse_history_ids))):

                        votes_d = json.loads(r[0].votes) if r[0].votes else {}
                        current_user_has_voted = str(user.id) in votes_d.keys()

                        if r[0].owner_id in friend_ids:
                            topics[r[1].id]={"verse_id":r[0].id, "topic_id":r[1].id, "email_address":r[2].email_address,
                                    "user_name":r[2].user_name, "src":'joined_friend', "next_index_user_ids":r[0].next_index_user_ids, 
                                    "user_ids":r[0].user_ids, "owner_id":r[0].owner_id, "title":r[0].title,
                                    "current_user_has_voted":current_user_has_voted, "complete":r[0].complete,
                                    "num_lines":r[0].num_lines
                                    }
                        else:
                            topics[r[1].id]={"verse_id":r[0].id, "topic_id":r[1].id, "email_address":r[2].email_address,
                                    "user_name":r[2].user_name, "src":'joined_world', "next_index_user_ids":r[0].next_index_user_ids, 
                                    "user_ids":r[0].user_ids, "owner_id":r[0].owner_id, "title":r[0].title,
                                    "current_user_has_voted":current_user_has_voted, "complete":r[0].complete,
                                    "num_lines":r[0].num_lines
                                    }

                # friendships
                for r in session.query(V, T, U).filter(V.verse_category_topic_id==T.id).\
                    filter(V.owner_id.in_(friend_ids)).\
                    filter(U.id!=user.id).\
                    filter(V.friends_only==True).\
                    filter(V.participant_count<V.max_participants).\
                    filter(T.id.in_(get_open_topic_keys(topics))).\
                    filter(not_(V.id.in_(verse_history_ids))):

                    votes_d = json.loads(r[0].votes) if r[0].votes else {}
                    current_user_has_voted = str(user.id) in votes_d.keys()

                    topics[r[1].id]={"verse_id":r[0].id, "topic_id":r[1].id, "email_address":r[2].email_address,
                        "user_name":r[2].user_name, "src":'friend', "next_index_user_ids":r[0].next_index_user_ids, 
                        "user_ids":r[0].user_ids, "owner_id":r[0].owner_id, "title":r[0].title,
                        "current_user_has_voted":current_user_has_voted, "complete":r[0].complete,
                        "num_lines":r[0].num_lines
                        }

                # put global open verses last, so mine and friends show up first in topics view
                # global open verses and topics that are not mine
                for r in session.query(V, T, U).filter(V.verse_category_topic_id==T.id).\
                    filter(V.owner_id==U.id).\
                    filter(U.id!=user.id).\
                    filter(V.friends_only==False).\
                    filter(V.participant_count<V.max_participants).\
                    filter(T.id.in_(get_open_topic_keys(topics))).\
                    filter(not_(V.id.in_(verse_history_ids))):

                    votes_d = json.loads(r[0].votes) if r[0].votes else {}
                    current_user_has_voted = str(user.id) in votes_d.keys()

                    topics[r[1].id]={"verse_id":r[0].id, "topic_id":r[1].id, "email_address":r[2].email_address,
                        "user_name":r[2].user_name, "src":'world', "next_index_user_ids":r[0].next_index_user_ids, 
                        "user_ids":r[0].user_ids, "owner_id":r[0].owner_id, "title":r[0].title,
                        "current_user_has_voted":current_user_has_voted, "complete":r[0].complete,
                        "num_lines":r[0].num_lines
                        }

                # TODO: optimize this - definitely a better way
                results = []
                for k in topics:
                    if topics[k]!=None:
                        results.append(topics[k])

                res = {"results":results, "user_level":user.level, "user_score":user.user_score, 
                    "num_of_favorited_lines":user.num_of_favorited_lines}
                print res
                return res

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
        print 'retrieving topics'
        # auth_usrid = authenticated_userid(request)
        # user, user_type_names, user_type_lookup = (
        #     get_current_rbac_user(auth_usrid,
        #         accept_user_type_names=[
        #             'sys',
        #             'player'
        #         ]
        #     )
        # )

        # if user and user.is_active and user.email_address==auth_usrid:
        topics = []

        with SQLAlchemySessionFactory() as session:
            
            T = ~VerseCategoryTopic

            # see if the user is associated to a verse for this topic
            # change the limit later
            for t in session.query(T).order_by(T.id).limit(64):
                topics.append({"id":t.id, "name":t.name, "min_points_req":t.min_points_req, 
                    "score_modifier":t.score_modifier, "main_icon_name":t.main_icon_name,
                    "verse_category_type_id":t.verse_category_type_id})

        return {"results":topics}

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
        print 'get_user_active_verses'
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

            with SQLAlchemySessionFactory() as session:
                return get_verse(verseId, user.id, session)

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
    name='verse-history',
    request_method='GET',
    context='poeticjustice:contexts.Users',
    renderer='json')
def get_users_verse_history(request):
    try:
        print 'get_users_verse_history'
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

                U, V, UVH = ~User, ~Verse, ~UserVerseHistory
                rp = (session.query(UVH)
                        .filter(UVH.player_id==user.id)
                        .order_by(UVH.last_upd)
                        ).all()

                results = []
                for uvh in rp:
                    uvh_d = UserVerseHistory(entity=uvh).to_dict()
                    uvh_d['verse_key'] = IDCODER.encode(int(uvh_d['id']))
                    results.append(uvh_d)

                res = dict(
                    status='Ok',
                    results=[UserVerseHistory(entity=uvh).to_dict() for uvh in rp],
                    logged_in=auth_usrid
                    )
                print res
                return res

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
    request_method='GET',
    context='poeticjustice:contexts.Verses',
    renderer='json')
def verse_using_get_for_testing(request):
    try:
        args = list(request.subpath)
        kwds = _process_subpath(request.subpath)
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
                return get_verse(kwds['id'], user.id, session)

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
            with SQLAlchemySessionFactory() as session:
                return get_verse(verseId, user.id, session)

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
    name='level-progress',
    request_method='GET',
    context='poeticjustice:contexts.Users',
    renderer='json')
def get_user_level_up_progress(request):
    print 'returning user level up progress'
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
            return get_level_progress(user.id, user.level)

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

def get_level_progress(userId, level):
    # this function can be used to determine if a user should level
    # up.  just need to make sure num_completed_verses = total_verses.
    # also, num_incomplete_verses should be zero

    num_lines = 0 # num of total lines
    num_complete_verses = 0 # started and completed
    num_incomplete_verses = 0 # started, but not done
    
    # num of completed verses required for the level
    num_verses_required = {1:16, 2:24, 3:32, 4:40, 5:48, 6:56, 7:64}[level]

    verses = {}

    with SQLAlchemySessionFactory() as session:
        U, LxV, V = ~User, ~LineXVerse, ~Verse
        for r in session.query(V, LxV).filter(LxV.verse_id==V.id).\
            filter(LxV.user_level==level).\
            filter(LxV.user_id==userId):
            num_lines += 1
            verses[r[0].id]=r[0].complete

    for k in verses:
        if verses[k]==True:
            num_complete_verses += 1
        else:
            num_incomplete_verses += 1

    return {"results":{"num_lines":num_lines, "num_complete_verses":num_complete_verses,
        "num_incomplete_verses":num_incomplete_verses, "num_verses_required":num_verses_required,
        "current_level":level}}


def do_level_up(user):
    # return true if the user should level up from their current level
    level = get_level_progress(user.id, user.level)
    return level["results"]["num_complete_verses"]==level["results"]["num_verses_required"]

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

            with SQLAlchemySessionFactory() as session:

                verse = session.query(~Verse).filter((~Verse).id==verseId).first()

                verse.next_index_user_ids = verse.next_index_user_ids + 1

                # current number of lines for the verse
                verse.num_lines = verse.num_lines + 1

                if verse.next_index_user_ids==len(verse.user_ids):
                    verse.next_index_user_ids = 0

                # finally, save this users line
                linexverse = LineXVerse(user_id=user.id, verse_id=verse.id, line_text=line, line_score=1, user_level=user.level)
                linexverse.save(session=session)

                user = User(entity=session.merge(user))
                user.user_score = user.user_score + 1

                verse = Verse(entity=session.merge(verse))
                setattr(verse, 'next_index_user_ids', verse.next_index_user_ids)
                verse.save(session=session)

                if (do_level_up(user)):
                    print 'user is leveling up'
                    user.level = user.level + 1
                else:
                    print 'user is not leveling up'

                user.save(session=session)

                res = get_verse(verse.id, user.id, session)

                if len(res['results']['votes']) == len(res['results']['user_ids']):
                    # everyone's voted
                    if verse.complete:
                        verse.complete = True
                        verse.save(session=session)
                        verse.commit()

                return res

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


def get_approved_user_friends(userId):
    # return all approved friend ids for a user
    friends = []
    with SQLAlchemySessionFactory() as session:
        U, UxU = ~User, ~UserXUser
        for r in session.query(U, UxU).filter(U.id==userId).\
            filter(U.id==UxU.user_id).\
            filter(UxU.approved==True):
            friends.append(r[1].friend_id)

        for r in session.query(U, UxU).filter(U.id==userId).\
            filter(U.id==UxU.friend_id).\
            filter(UxU.approved==True):
            friends.append(r[1].user_id)
    return friends

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
                    if user.id not in get_approved_user_friends(v.owner_id):
                        raise HTTPUnauthorized
                        
                if v.participant_count >= v.max_participants:
                    raise HTTPConflict

                is_next = False

                open_verse_ids = copy.deepcopy(user.open_verse_ids)
                if not open_verse_ids:
                    open_verse_ids = []
                open_verse_ids.append(v.id)
                setattr(user, 'open_verse_ids', open_verse_ids)
                user.save(session)

                user_ids = copy.deepcopy(v.user_ids)

                if -1 in v.user_ids:
                    # there's still a user slot available, so let's grab it

                    # first assign the next index id to the available slot
                    index = v.user_ids.index(-1)

                    # next update the verse user_ids array for this user
                    user_ids[index]=user.id

                    setattr(v, 'user_ids', user_ids)

                    v.participant_count += 1

                    # check if the previous user submitted their line
                    last_user_id = user_ids[index-1]
                    LXV = ~LineXVerse
                    line = session.query(LXV).filter(LXV.verse_id==v.id).\
                        filter(LXV.user_id==last_user_id).first()

                    if line:
                        is_next = True
                    
                    v.save(session)

                    user = User.load(user.id, session=session)

                    res = dict(
                        is_next=is_next,
                        verse=v.to_dict(),
                        logged_in=auth_usrid,
                        user=user.to_dict()
                    )
                    
                    return res

                else:
                    raise HTTPConflict

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


def get_verse_user_data(verse, session):
    U = ~User
    sq = (session.query(U.id)
            .filter(U.id.in_(verse.user_ids))
            ).subquery()
    rp = (session.query(U.id, U.user_name, U.user_prefs, U.user_score, U.level, U.country_code, U.num_of_favorited_lines)
            .filter(U.id.in_(sq))
            ).all()

    # users [(id, email_address)]
    users = [(row[0], row[1], 
                row[2] if row[0] else "", row[3], row[4], 
                row[5] if row[5] else 'earth_flag',
                row[6]) for row in rp]

    print 'USERS DATA', users

    return users


def get_verse_to_view(verse_id, session):
    lines = OrderedDict()
    verse = None
    users = {}
    if verse_id > 0:

        U, V, LxV = ~User, ~Verse, ~LineXVerse
        for row in session.query(V, LxV) \
                .filter(V.id==verse_id) \
                .filter(LxV.verse_id==verse_id) \
                .order_by(LxV.id):
            lines[row.LineXVerse.id] = (row.LineXVerse.user_id, row.LineXVerse.line_text)
            if not verse:
                verse = row.Verse

        # TODO: what about player's that join a verse, write a line, then leave?
        if verse: # maybe no lines at all?
            users = get_verse_user_data(verse, session)
            verse = Verse(entity=verse)

        else:
            verse = Verse.load(int(verse_id), session) 
            if not verse.user_ids:
                ud = (session.query(U.id, U.user_name, U.user_prefs, U.user_score, U.level, U.country_code)
                        .filter(U.id==verse.owner_id)
                        ).first()
                if ud:
                    users = ud
            else:
                users = get_verse_user_data(verse, session)

    return \
        verse, dict(
                results=dict(
                    verse=verse.to_dict(),
                    lines=lines,
                    verse_id=verse_id,
                    user_data=users,
                    owner_id=verse.owner_id)
                )


@view_config(
    name='viewable',
    request_method='GET',
    context='poeticjustice:contexts.Verses',
    renderer='json',
    permission='edit')
def view_verse(request):
    """

    JSON repr
    ---------

    {'status': 'Ok',
     'results': {
           'lines': {'3': [11116, 'say some shit']},
           'owner_id': -1,
           'user_data': [[11116,
                          'mat',
                          '{"avatar_name": "avatar_jamaican_guy.png"}']],
           'verse': {'complete': False,
                     'current_user_id': 'None',
                     'friends_only': True,
                     'id': 7,
                     'key': '6F5QRNXPMS9W1BDK',
                     'max_lines': 16,
                     'max_participants': 4,
                     'next_index_user_ids': 1,
                     'owner_id': 11116,
                     'participant_count': 1,
                     'title': 'Reno tennis',
                     'user_ids': [11116, -1, -1, -1],
                     'verse_category_topic_id': 6},
           'verse_id': '7'}}

    """

    print 'view_verse called', request
    try:
        args = list(request.subpath)
        # kwds = _process_subpath(request.subpath, formUrlEncodedParams=request.POST)
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

                verse, jsonable = get_verse_to_view(kwds['id'], session)

                res = dict(
                    status="Ok",
                    )
                res.update(jsonable)
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


def close_verse_add_to_history(verse_id, user, session):

    verse, jsonable = get_verse_to_view(verse_id, session)

    user_version_history = None

    if verse:

        verse.complete = True
        session.add(verse)

        for user_data in jsonable['results']['user_data']:

            print user_data
            # U.id, U.user_name, U.user_prefs, U.user_score, U.level

            user_id, user_name, user_prefs, score, level, country_code, num_favs = user_data

            lines_json = json.dumps(jsonable['results']['lines'])

            players_json = json.dumps(jsonable['results']['user_data'])

            print 'players_json', players_json

            user_version_history = UserVerseHistory(
                    verse_id=verse.id,
                    owner_id=verse.owner_id,
                    player_id=user_id,
                    topic_id=verse.verse_category_topic_id,
                    title=verse.title,
                    lines_record=lines_json,
                    players_record=players_json,
                    votes_record=verse.votes,
                    user_ids=verse.user_ids,
                    level=level
                    ).save(session)

        return verse, jsonable, user_version_history


@view_config(
    name='close',
    request_method='GET',
    context='poeticjustice:contexts.Verses',
    renderer='json',
    permission='edit')
def close_verse(request):
    print 'close_verse called', request
    try:
        args = list(request.subpath)
        # kwds = _process_subpath(request.subpath, formUrlEncodedParams=request.POST)
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

                verse, jsonable, user_version_history = \
                    close_verse_add_to_history(kwds['id'], user, session)

                return dict(
                    status="Ok",
                    verse=verse.to_dict() if verse else None,
                    verse_rec=jsonable,
                    user_version_history=\
                        user_version_history.to_dict(ignore_fields=['lines_record']) \
                        if user_version_history else None,
                    user=user.to_dict()
                    )

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


@view_config(
    name='cancel',
    request_method='GET',
    context='poeticjustice:contexts.Verses',
    renderer='json',
    permission='edit')
def cancel_verse(request):
    print 'close_verse called', request
    try:
        args = list(request.subpath)
        # kwds = _process_subpath(request.subpath, formUrlEncodedParams=request.POST)
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

                verse, jsonable = get_verse_to_view(kwds['id'], session)
                user_ids = [u[0] for u in jsonable['results']['user_data']]

                U = ~User
                for player in (
                    session.query(U)
                        .filter(U.id.in_(user_ids))
                        ):

                        if player and player.open_verse_ids:
                            if verse.id in player.open_verse_ids:
                                open_verse_ids = copy.deepcopy(player.open_verse_ids)
                                if len(open_verse_ids) > 0:
                                    open_verse_ids.remove(verse.id)
                                setattr(player, 'open_verse_ids', open_verse_ids)
                                session.add(player)

                session.commit()

                def del_it():
                    # bulk delete line x verses
                    LxV = ~LineXVerse
                    session.query(LxV).filter(LxV.verse_id==verse.id).delete(synchronize_session='fetch')

                    print 'before delete of verse', verse, jsonable
                    # finally, delete the verse
                    session.delete(~verse)

                    session.commit()


                try:
                    del_it()
                except:
                    print traceback.format_exc()
                    try:
                        time.sleep(1)
                        del_it()
                    except:
                        raise HTTPConflict

                return dict(
                    status="Ok",
                    verse=verse.to_dict() if verse else None,
                    user=user.to_dict()
                    )

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

















