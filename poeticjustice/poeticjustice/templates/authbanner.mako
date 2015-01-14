<%def name="get_auth_banner(url, came_from, login, password, logged_in)">
    %if logged_in == None:
        <div class="contain-to-grid sticky">
            <nav class="top-bar">
                <ul class="title-area">
                    <!-- Title Area -->
                    <li class="name">
                        <h1><a href="#">Mividio</a></h1>
                    </li>
                    <!-- Remove the class "menu-icon" to get rid of menu icon. Take out "Menu" to just have icon alone -->
                    <li class="toggle-topbar menu-icon"><a href="#"><span>Menu</span></a></li>
                </ul>
                <section class="top-bar-section">
                    <!-- Right Nav Section -->
                    <ul class="right">
                        <li class="divider hide-for-small"></li>
                        <li class="divider"></li>

                        <li class="has-form">
                            <form id="form_login" action="${url}" method="POST">
                                <input type="hidden" name="came_from" value="${came_from}"/>
                                <div class="row">
                                    <div class="small-1 columns">
                                        <label for="right-label" class="right">Email</label>
                                    </div>
                                    <div class="small-3 columns">
                                        <input type="text" id="input_email_address" name="login"
                                               value="${login}"/>
                                    </div>
                                    <div class="small-2 columns">
                                        <label for="right-label" class="right">Password</label>
                                    </div>
                                    <div class="small-3 columns">
                                        <input type="password" id="input_password" name="password"
                                               value="${password}"/>
                                    </div>
                                    <div class="small-3 columns">
                                        <input type="submit" class="button" title="Login" value="Login"
                                               name="form.submitted"/>
                                    </div>
                                </div>
                            </form>
                        </li>
                    </ul>
                </section>
            </nav>
        </div>
    %else:
        <div class="contain-to-grid sticky">
            <nav class="top-bar">
                <ul class="title-area">
                    <!-- Title Area -->
                    <li class="name">
                        <h1><a href="/users/dashboard">Mividio</a></h1>
                    </li>
                    <li class="toggle-topbar menu-icon"><a href="#"><span>Menu</span></a></li>
                </ul>
                <section class="top-bar-section">
                    <!-- Right Nav Section -->
                    <ul class="right">
                        <li class="divider hide-for-small"></li>
                        <li class="divider"></li>
                        <li><a href="/users/edit">${logged_in}</a></li>
                        <li><a class="button" href="/logout">Logout</a></li>
                    </ul>
                </section>
            </nav>
        </div>
    %endif
</%def>

<%def name="get_login_banner(logged_in)">
    %if logged_in != None:
        <div class="contain-to-grid sticky">
            <nav class="top-bar">
                <ul class="title-area">
                    <!-- Title Area -->
                    <li class="name">
                        <h1><a href="/users/dashboard">Mividio</a></h1>
                    </li>
                    <li class="toggle-topbar menu-icon"><a href="#"><span>Menu</span></a></li>
                </ul>
                <section class="top-bar-section">
                    <!-- Right Nav Section -->
                    <ul class="right">
                        <li class="divider hide-for-small"></li>
                        <li class="divider"></li>
                        <li><a href="/users/edit">${logged_in}</a></li>
                        <li><a class="button" href="/logout">Logout</a></li>
                    </ul>
                </section>
            </nav>
        </div>
    %endif
</%def>

