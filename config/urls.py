from django.contrib import admin
from django.urls import path, include
from django.views.generic import RedirectView
from web import views, api, actions

# Redirect /admin path to / root but lets login possible
admin_patterns = ([
    path('login/', admin.site.login, name='login'),
    path('', RedirectView.as_view(url='/', permanent=False), name='index'),
], 'admin')

urlpatterns = [
    path('admin/', include(admin_patterns)),                                # Permit admin requests
    path('i18n/', include('django.conf.urls.i18n')),                        # Request translations
    
    path('endpoint', api.receive_system_info, name='receive_system_info'),  # Endpoint to receive Alfred data          

    # Dashboard redirection
    path('', views.dashboard_view, name='dashboard'),

    # Actions
    path('logout', actions.disconnect, name='logout'),
    path('settings/', actions.admin_settings, name='editsetting'),
    path('user/create/', actions.add_user, name='adduser'), 
]