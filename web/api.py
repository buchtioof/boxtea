import json
from django.http import JsonResponse
from django.conf import settings
from django.views.decorators.csrf import csrf_exempt
from .models import SystemInfo, SystemMetrics

@csrf_exempt
def receive_system_info(request):
    # Token verification
    key = request.META.get('HTTP_X_API_KEY')
    if key != settings.SESSION_TOKEN:
        return JsonResponse({'error': 'Access Refused: Session token not right/available'}, status=401)

    if request.method == 'POST':
        # Adding Daemon "Jarvis" treatment later
        return JsonResponse({'message': 'READY'}, status=200)

    return JsonResponse({'error': 'Only POST method is allowed'}, status=405)