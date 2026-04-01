import os
from django.db import IntegrityError
from django.conf import settings
from django.contrib import messages
from django.shortcuts import render, get_object_or_404, redirect
from django.contrib.admin.views.decorators import staff_member_required
from django.contrib.auth import logout, update_session_auth_hash
from django.utils.translation import gettext as _
from django.utils import translation
from .models import SystemInfo, Employees

# Logout action
def disconnect(request):
    logout(request)
    return redirect('admin:login')

# Settings set of actions
@staff_member_required(login_url='admin:login')
def admin_settings(request):
    if request.method == 'POST':
        user = request.user
        new_username = request.POST.get('new_username')
        new_password = request.POST.get('new_password')
        new_timezone = request.POST.get('timezone')
        new_language = request.POST.get('language')
        
        user_updated = False

        if new_username and new_username != user.username:
            user.username = new_username
            user_updated = True
        
        if new_password:
            user.set_password(new_password)
            user_updated = True
        
        if user_updated: 
            try:
                user.save()
                if new_password:
                    update_session_auth_hash(request, user)
                messages.success(request, _("[OK] Profile updated successfully!"))
            except IntegrityError:
                messages.error(request, _("[ERROR] This username is already taken."))
                return redirect(request.META.get('HTTP_REFERER', '/'))

        tz_updated = False
        lang_updated = False
        response = redirect(request.META.get('HTTP_REFERER', '/'))

        if new_timezone:
            request.session['django_timezone'] = new_timezone
            tz_updated = True
        
        if new_language:
            translation.activate(new_language)
            response.set_cookie(settings.LANGUAGE_COOKIE_NAME, new_language)
            lang_updated = True
        
        if tz_updated:
            messages.success(request, _("[OK] Timezone updated successfully!"))
        if lang_updated:
            messages.success(request, _("[OK] Language updated successfully!"))
            
        return response
            
    return redirect(request.META.get('HTTP_REFERER', '/'))

@staff_member_required(login_url='admin:login')
def add_user(request):

    if request.method == 'POST':
        
        if 'add_user' in request.POST:
            username = request.POST.get('username')
            first_name = request.POST.get('first_name')
            last_name = request.POST.get('last_name')
            password = request.POST.get('password')
            quota = int(request.POST.get('quota', 5000))
            samba_access = request.POST.get('samba_access') == 'on'
            
            if username and first_name and last_name and password:
                try:
                    # Create user in DB
                    Employee.objects.create(
                        username=username, 
                        first_name=first_name, 
                        last_name=last_name, 
                        storage_quota=quota,
                        has_samba_access=samba_access
                    )
                    
                    # Create user in Linux
                    subprocess.run(['sudo', 'useradd', '-m', '-s', '/bin/bash', username], check=True)
                    
                    # Add password to user
                    subprocess.run(['sudo', 'chpasswd'], input=f"{username}:{password}\n", text=True, check=True)

                    # Give samba privileges
                    if samba_access:
                        subprocess.run(['sudo', 'smbpasswd', '-s', '-a', username], input=f"{password}\n{password}\n", text=True, check=True)

                    # Manage storage quota
                    if quota > 0:
                        soft_limit = str(quota * 1024)
                        hard_limit = str(int(quota * 1024 * 1.1)) # Let +10% space for hard limit
                        subprocess.run(['sudo', 'setquota', '-u', username, soft_limit, hard_limit, '0', '0', '/'], check=True)

                    messages.success(request, _("[OK] The user {user} has been successfully created!").format(user=username))
                
                except IntegrityError:
                    messages.error(request, _("[ERROR] This username is already used. Please choose another one."))
                except subprocess.CalledProcessError as e:
                    messages.error(request, _("[INTERNAL ERROR] An error occured from your Linux system: {e}").format(e=str(e)))
                except Exception as e:
                    messages.error(request, _("[ERROR] {e}").format(e=str(e)))
    
    return redirect(request.META.get('HTTP_REFERER', '/'))