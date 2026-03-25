# Models.py: Database configuration

from django.db import models
from django.core.exceptions import ValidationError

# Table of the users
class Employees(models.Model):

    username = models.CharField(max_length=50, unique=True)

    first_name = models.CharField(max_length=64)
    last_name = models.CharField(max_length=64)
    email = models.EmailField(max_length=255, blank=True, null=True)
    
    has_samba_access = models.BooleanField(default=True)
    storage_quota = models.IntegerField(default=5000) # Megaoctet
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.first_name} {self.last_name} ({self.username})"

# Manage Samba configuration
class SharedSamba(models.Model):

    shared_folder_name = models.CharField(max_length=128, unique=True)
    path = models.CharField(max_length=255)
    description = models.TextField(blank=True, null=True)
    
    is_public = models.BooleanField(default=False)
    is_read_only = models.BooleanField(default=False)
    
    # Many-to-Many: Permit multiple users to access multiple folders
    allowed_employees = models.ManyToManyField(Employee, blank=True, related_name='accessible_folders')

    def __str__(self):
        return self.name

# Fetch System Metrics (Updated each X minutes)
class SystemMetrics(models.Model):

    timestamp = models.DateTimeField(auto_now_add=True, db_index=True)
    
    cpu_usage = models.FloatField()
    cpu_temperature = models.FloatField(null=True, blank=True)
    ram_usage_mb = models.IntegerField()
    disk_usage_percent = models.FloatField()

    # Order table data by the "timestamp" value
    class Meta:
        ordering = ['-timestamp']

    def __str__(self):
        return f"Data fetched at {self.timestamp.strftime('%Y-%m-%d %H:%M:%S')}"

# Fetch System Hardware data (Only fetched at boot)
class SystemInfo(models.Model):

    cpu_model = models.CharField(max_length=255, null=True, blank=True)
    cpu_cores = models.IntegerField(null=True, blank=True)
    total_ram = models.IntegerField(null=True, blank=True) # Megaoctet
    total_storage = models.IntegerField(null=True, blank=True) # Gigaoctet
    system_info = models.CharField(max_length=255, null=True, blank=True)
    
    last_updated = models.DateTimeField(auto_now_add=True)

    # Order table data by the "last_updated" value in order to specifically use the latest fetch
    class Meta:
        ordering = ['-last_updated']

    def __str__(self):
        return f"BoxTea Server - {self.last_updated.strftime('%d/%m/%Y %H:%M')}"