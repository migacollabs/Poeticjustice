import os
import sys
import time
import json
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

import poeticjustice
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


ASSETS_DIR = os.path.dirname(os.path.abspath(poeticjustice.assets.__file__))


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

def _save_user(user, session):

    user.password = sha512("NOPASSWORD").hexdigest()
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


def _send_notification(user_obj, auth_hash, email_tmpl_file, logo_name=None):

    ac = get_app_config()
    dconfig = get_dinj_config(ac)

    # send email
    email_tmpl = os.path.join(dconfig.Web.TemplateDir, email_tmpl_file)

    site_addr = get_site_addr()

    tmpl_vars = {
        'site_id': 'mividio',
        'site_hostname': site_addr,
        'site_display_name': 'Mividio',
        'auth_hash': auth_hash
    }
    tmpl_vars.update(user_obj.to_dict(ignore_fields=['id', 'key']))

    message_body = Template(filename=email_tmpl).render(**tmpl_vars)

    # email the new user
    smtp_psswd = os.environ['POETIC_JUSTICE_SMTP_PASSWORD']
    smtp_user = os.environ['POETIC_JUSTICE_SMTP_USER']
    smtp_server = os.environ['POETIC_JUSTICE_SMTP_SERVER']

    emailer = Emailer(
        smtp_user, 
        smtp_psswd, 
        smtp_server) \
    .send_html_email({
        'to': user_obj.email_address,
        'from': smtp_user,
        'subject': 'Poetic Justice - Verify your email!',
        'message_body': message_body},
        attached_logo=os.path.join(ASSETS_DIR, logo_name) if logo_name else None)


@view_config(
    name='invite',
    request_method='POST',
    context='poeticjustice:contexts.Users',
    permission='edit',
    renderer='json')
def invite_new_user_post(request):
    """ """
    try:
        print 'invite_new_user_post', request
        args = list(request.subpath)
        kwds = _process_subpath(
            request.subpath, formUrlEncodedParams=request.POST)
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
        with SQLAlchemySessionFactory() as session:

            invite_user = (session.query(~User)
                        .filter((~User).email_address==kwds['email_address'].lower())
                        ).first()

            if invite_user:
                raise HTTPConflict
            else:
                # This is a brand new user
                invite_user = User(**kwds)

            invite_user.access_token = \
                sha512(
                    str(invite_user.id) + str(invite_user.initial_entry_date) + default_hashkey
                ).hexdigest()

            invite_user.is_active = True
            

        site_addr = get_site_addr()

        invite_user.save(session=session)

        grp_lut = LutValues(model=Group)
        utl_lut = LutValues(model=UserTypeLookup)

        grp_ids = set()
        grp_ids.add(grp_lut.get_id('user'))

        UserXUserTypeLookup(
            user_id=invite_user.id, 
            user_type_id=utl_lut.get_id('player')
            ).save(session=session)

        grp_ids.add(grp_lut.get_id('editor'))

        # add to correct group (permission role)
        grp_ids = list(grp_ids)
        grp_ids.sort()
        # lowest is best
        UserXGroup(
            user_id=invite_user.id, 
            group_id=grp_ids[0]
            ).save(session=session)

        UserXUser(
            user_id=user.id,
            friend_Id=invite_user.id
            ).save(session=session)


        result = make_result_repr(
            User,
            [invite_user],
            logged_in=auth_usrid,
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
        # password = ''
        ac = get_app_config()
        dconfig = get_dinj_config(ac)

        device_token = request.params['device_token'] if 'device_token' in request.params else None
        device_type = request.params['device_type'] if 'device_type' in request.params else None

        if not device_token and device_type != "DEVICETYPEBROWSER":
            raise HTTPForbidden

        if 'form.submitted' in request.params:
            login = request.params['login']
            # password = sha512("NOPASSWORD").hexdigest()
            user = get_user(login)

            with SQLAlchemySessionFactory() as session:
                if user:
                    if user.email_address == login:

                        U = ~User
                        # TODO: .first() didn't work here for some reason
                        for user_obj in session.query(U).filter(U.email_address==login):
                            pass

                        # update to the latest user
                        user = User(entity=user_obj)

                        if user.access_token == None:
                            return dict(
                                status='Ok',
                                verification_req=True,
                                user=user.to_dict(),
                                logged_in=None
                                )

                        user.user_name = request.params['user_name']

                        device_rec = json.loads(user.device_rec) if user.device_rec else {}

                        if device_token and (len(device_rec) > 0 and device_token not in device_rec):

                            # send email if more than one device ?

                            device_rec[device_token] = True

                            # new device
                            auth_hash = sha512(user_obj.email_address + default_hashkey).hexdigest()
                            user.auth_hash = auth_hash
                            _send_notification(user, auth_hash, 
                                "email.verification.mako", 
                                logo_name="Conversation.png")

                            user.device_rec = json.dumps(device_rec)

                        elif device_token not in device_rec:
                            device_rec[device_token] = True
                            user.device_rec = json.dumps(device_rec)


                        user.save(session=session)

                        headers = remember(request, login)
                        request.response.headerlist.extend(headers)

                        return dict(
                            status='Ok',
                            verification_req=False,
                            user=User(entity=user_obj).to_dict(),
                            logged_in=authenticated_userid(request)
                            )

                else:
                    user_obj = session.query(~User).filter((~User).email_address==login).first()

                    if user_obj is None:
                        user_obj = User(
                            email_address=login,
                            password=sha512("NOPASSWORD").hexdigest(),
                            user_name=request.params['user_name'] if 'user_name' in request.params else None,
                            country_code=request.params['country_code'] if 'country_code' in request.params else "USA")

                        user_obj.save(session=session)

                        device_rec_json = json.dumps(user_obj.device_rec) if user_obj.device_rec else None

                        print device_rec_json

                        auth_hash = sha512(user_obj.email_address + default_hashkey).hexdigest()

                        user_obj.auth_hash = auth_hash


                        # send email
                        email_tmpl = os.path.join(
                            dconfig.Web.TemplateDir, 'email.verification.mako')

                        site_addr = get_site_addr()

                        tmpl_vars = {
                            'site_id': 'mividio',
                            'site_hostname': site_addr,
                            'site_display_name': 'Mividio',
                            'auth_hash': auth_hash
                        }
                        tmpl_vars.update(user_obj.to_dict(ignore_fields=['id', 'key']))

                        message_body = Template(filename=email_tmpl).render(**tmpl_vars)

                        # email the new user
                        smtp_psswd = os.environ['POETIC_JUSTICE_SMTP_PASSWORD']
                        smtp_user = os.environ['POETIC_JUSTICE_SMTP_USER']
                        smtp_server = os.environ['POETIC_JUSTICE_SMTP_SERVER']

                        emailer = Emailer(
                            smtp_user, 
                            smtp_psswd, 
                            smtp_server) \
                        .send_html_email({
                            'to': user_obj.email_address,
                            'from': smtp_user,
                            'subject': 'Poetic Justice - Verify your email!',
                            'message_body': message_body},
                            attached_logo=os.path.join(ASSETS_DIR, "Conversation.png"))


                        # save new user
                        user_obj = _save_user(user_obj, session)


                    user = get_user(login, force_refresh=True)
                   
                    headers = remember(request, login)
                    request.response.headerlist.extend(headers)

                    return dict(
                        status='Ok',
                        verification_req=True,
                        user=User(entity=user_obj).to_dict(),
                        logged_in=user_obj.email_address
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
    name='verify',
    request_method='GET',
    context='poeticjustice:contexts.Users',
    renderer='user.verified.mako')
def verify_new_user(request):
    try:
        args = list(request.subpath)
        kwds = _process_subpath(args)
        with SQLAlchemySessionFactory() as session:
            U = ~User
            user = session.query(U).filter((U).auth_hash == kwds['hash']).first()
            if user:
                h = sha512(user.email_address + default_hashkey).hexdigest()
                if h == kwds['hash']:

                    user.access_token = sha512(
                        str(user.id) + str(user.initial_entry_date) + default_hashkey).hexdigest()

                    session.add(user)
                    session.commit()
                    user = User(entity=user)

                    print 'VERIFIED NEW USER'
                    
                else:
                    raise HTTPForbidden()
            else:
                raise HTTPUnauthorized()

            return {
                'verified': True,
                'email_address': user.email_address,
                'logged_in': authenticated_userid(request),
                'user': user
            }

    except HTTPGone: raise
    except HTTPFound: raise
    except HTTPUnauthorized: raise
    except:
        log.exception(traceback.format_exc())
        raise HTTPBadRequest(explanation='Invalid query parameters')
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

