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
from pyaella.server.api import get_current_user
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
    name='new',
    request_method='GET',
    context='poeticjustice:contexts.Users',
    renderer='create.new.user.mako')
def create_new_user(request):
    try:
        print 'create_new_user', request
        args = list(request.subpath)
        kwds = _process_subpath(args)
        auth_usrid = authenticated_userid(request)
        session = get_session()
        return dict(
            logged_in=auth_usrid,
            user=get_current_user(auth_usrid, session=session)
        )

    except HTTPFound: raise
    except:
        log.exception(traceback.format_exc())
        raise HTTPBadRequest(explanation='Bad Request')
    finally:
        try:
            session.close()
        except:
            pass


def _active_user(user, session):

    user.password = sha512("NOPASSWORD").hexdigest()
    user.access_token = \
        sha512(
            str(user.id) + str(user.initial_entry_date) + default_hashkey
        ).hexdigest()
    user.device_token = "NODEVICETOKEN"
    user.country_code = 'USA'
    user.is_active = True

    user.save(session=session)

    grp_lut = LutValues(model=Group)
    utl_lut = LutValues(model=UserTypeLookup)

    grp_ids = set()
    grp_ids.add(grp_lut.get_id('user'))

    UserXUserTypeLookup(
        user_id=user.id, 
        user_type_id=utl_lut.get_id('player')
        ).save(session=session)

    grp_ids.add(grp_lut.get_id('editor'))

    # add to correct group (permission role)
    grp_ids = list(grp_ids)
    grp_ids.sort()
    # lowest is best
    uxg = UserXGroup(
        user_id=user.id, 
        group_id=grp_ids[0]
        )
    uxg.save(session=session)
    return user


@view_config(
    name='new',
    request_method='POST',
    context='poeticjustice:contexts.Users',
    renderer='json')
def create_new_user_post(request):
    """ """
    try:
        print 'create_new_user_post', request
        print 'create_new_user_post POST', request.POST
        args = list(request.subpath)
        kwds = _process_subpath(
            request.subpath, formUrlEncodedParams=request.POST)
        ac = get_app_config()
        dconfig = get_dinj_config(ac)
        with SQLAlchemySessionFactory() as session:

            user = (session.query(~User)
                        .filter((~User).email_address==kwds['email_address'].lower())
                        ).first()

            if user:
                raise HTTPConflict
            else:
                # This is a brand new user
                user = User(**kwds)

            user.access_token = \
                sha512(
                    str(user.id) + str(user.initial_entry_date) + default_hashkey
                ).hexdigest()
            user.device_token = "NODEVICETOKEN"
            user.is_active = True

        site_addr = get_site_addr()

        user.save(session=session)

        grp_lut = LutValues(model=Group)
        utl_lut = LutValues(model=UserTypeLookup)

        grp_ids = set()
        grp_ids.add(grp_lut.get_id('user'))

        UserXUserTypeLookup(
            user_id=user.id, 
            user_type_id=utl_lut.get_id('player')
            ).save(session=session)

        grp_ids.add(grp_lut.get_id('editor'))

        # add to correct group (permission role)
        grp_ids = list(grp_ids)
        grp_ids.sort()
        # lowest is best
        UserXGroup(
            user_id=user.id, 
            group_id=grp_ids[0]
            ).save(session=session)


        result = make_result_repr(
            User,
            [user],
            logged_in=user.email_address if user else None,
        )

        return result

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
    name='login',
    request_method='GET',
    context='poeticjustice:contexts.AppRoot',
    renderer='login.mako')
def login_get(request):
    args = list(request.subpath)
    kwds = _process_subpath(args)
    return {
        'url': '/login',
        'came_from': '/login',
        'login': '',
        'password': '',
        'message': '',
        'logged_in': authenticated_userid(request)
    }

@view_config(
    name='login',
    request_method='POST',
    context='poeticjustice:contexts.AppRoot',
    renderer='json')
@forbidden_view_config(renderer='login.mako')
def login_post(request):
    try:
        print '\nlogin post called\n', request
        login_url = request.resource_url(request.context, 'login')
        referrer = request.url
        if referrer == login_url:
            referrer = '/'
        came_from = request.params.get('came_from', referrer)
        message = ''
        login = ''
        password = ''
        if 'form.submitted' in request.params:
            login = request.params['login']
            password = sha512("NOPASSWORD").hexdigest()
            user = get_user(login)
            with SQLAlchemySessionFactory() as session:
                if user:
                    if user.password == password:
                        headers = remember(request, login)
                        request.response.headerlist.extend(headers)
                        U = ~User
                        user_obj = session.query(U).filter(U.email_address==login).first()
                        return dict(
                            status='Ok',
                            user=User(entity=user_obj).to_dict(),
                            logged_in=authenticated_userid(request)
                            )
                else:
                    user_obj = User(email_address=login, 
                        user_name=request.params['user_name'] if 'user_name' in request.params else None)
                    user_obj = _active_user(user_obj, session)
                    user = get_user(login, force_refresh=True)
                    headers = remember(request, login)
                    request.response.headerlist.extend(headers)
                    return dict(
                        status='Ok',
                        user=User(entity=user_obj).to_dict(),
                        logged_in=authenticated_userid(request)
                        )

        return dict(
            message='Failed login',
            url=request.application_url + '/login',
            came_from=came_from,
            login=login,
            logged_in=authenticated_userid(request)
        )

    except HTTPFound: raise
    except:
        log.exception(traceback.format_exc())
        raise HTTPBadRequest(explanation='Bad Request')
    finally:
        try:
            session.close()
        except:
            pass


@view_config(
    name='data',
    request_method='GET',
    context='poeticjustice:contexts.Users',
    renderer='json')
def user_data(request):
    print 'user_data called', request
    try:
        args = list(request.subpath)
        kwds = _process_subpath(args)
        auth_usrid = authenticated_userid(request)
        session = get_session()
        return dict(
            logged_in=auth_usrid,
            user=get_current_user(auth_usrid, session=session)
        )

    except HTTPFound: raise
    except:
        log.exception(traceback.format_exc())
        raise HTTPBadRequest(explanation='Bad Request')
    finally:
        try:
            session.close()
        except:
            pass


@view_config(
    context='poeticjustice:contexts.AppRoot',
    name='logout')
def logout(request):
    headers = forget(request)
    return HTTPFound(
        location='/login', headers=headers)

@view_config(
    name='welcome',
    context='poeticjustice:contexts.AppRoot',
    request_method='GET',
    renderer='default.mako')
def say_hello(request):
    return {'app_name': 'Poeticjustice'}

