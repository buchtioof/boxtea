import json
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from .models import SystemInfo, SystemMetrics

@csrf_exempt
def receive_system_info(request):
    if request.method != 'POST':
        return JsonResponse({'error': 'Only POST method is allowed'}, status=405)

    try:
        data = json.loads(request.body)
        hardware = data.get('HARDWARE', {})
    except json.JSONDecodeError:
        return JsonResponse({'error': 'Invalid JSON'}, status=400)

    SystemMetrics.objects.create(
        cpu_usage=hardware.get('cpu_usage_percent', 0),
        cpu_temperature=hardware.get('cpu_temp_c', 0.0),
        ram_usage_mb=hardware.get('ram_used_mb', 0),
        disk_usage_percent=hardware.get('storage_usage_percent', 0)
    )

    sys_info, created = SystemInfo.objects.get_or_create(id=1)
    sys_info.cpu_model = hardware.get('cpu_model', 'Unknown')
    sys_info.cpu_cores = hardware.get('cpu_cores', 0)
    sys_info.total_ram = hardware.get('ram_total_mb', 0)
    sys_info.total_storage = hardware.get('storage_total_gb', 0)
    sys_info.save()

    return JsonResponse({'message': 'Data successfully received and saved'}, status=200)