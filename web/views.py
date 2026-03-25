from django.shortcuts import render, get_object_or_404, redirect
from django.contrib.admin.views.decorators import staff_member_required
from .models import SystemInfo, Employees, SystemMetrics

# Actions from the dashboard.html
@staff_member_required(login_url='admin:login')
def dashboard_view(request):

    computer_info = SystemInfo.objects.first()
    
    employees = Employee.objects.all()
    
    metrics = SystemMetrics.objects.all()[:10]
    
    return render(request, 'dashboard.html', {
        'data': computer_info, 
        'employees': employees,
        'metrics': metrics
    })