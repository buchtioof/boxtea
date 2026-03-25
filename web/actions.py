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

##### LOGOUT #####
def disconnect(request):
    logout(request)
    return redirect('admin:login')

##### SETTINGS ACTIONS #####
# Employees management
@staff_member_required(login_url='admin:login')
def emp_settings(request):

    if request.method == 'POST':
        
        if 'add_employee' in request.POST:
            username = request.POST.get('username') 
            first_name = request.POST.get('first_name')
            last_name = request.POST.get('last_name')
            email = request.POST.get('email') 
            
            if username and first_name and last_name:
                Employees.objects.create(username=username, first_name=first_name, last_name=last_name, email=email)
                messages.success(request, _("[OK] Employee {first_name} {last_name} has been added.").format(first_name=first_name, last_name=last_name))

        elif 'edit_employee' in request.POST:
            emp_id = request.POST.get('employee_id')
            first_name = request.POST.get('first_name')
            last_name = request.POST.get('last_name')
            emp = get_object_or_404(Employees, id=emp_id)
            
            if first_name and last_name:
                emp.first_name = first_name
                emp.last_name = last_name
                emp_name = f"{emp.first_name} {emp.last_name}"
                emp.save()
                messages.success(request, _("[OK] Employee {emp_name} has been updated.").format(emp_name=emp_name))

        elif 'delete_employee' in request.POST:
            emp_id = request.POST.get('employee_id')
            emp = get_object_or_404(Employees, id=emp_id)
            emp_name = f"{emp.first_name} {emp.last_name}"
            emp.delete()
            messages.success(request, _("[OK] Employee {emp_name} has been deleted.").format(emp_name=emp_name))

    return redirect(request.META.get('HTTP_REFERER', '/'))

# Settings management
@staff_member_required(login_url='admin:login')
def user_settings(request):
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