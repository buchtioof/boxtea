from django.conf import settings

def version_processor(request):
    return {
        'boxtea_version': settings.BOXTEA_VERSION,
        'motor_used': settings.MOTOR_USED,
    }