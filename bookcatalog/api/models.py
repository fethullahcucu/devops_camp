from django.db import models

# Create your models here.

class Book(models.Model):
    title = models.CharField(max_length=255)
    description = models.TextField(blank=True)
    author = models.CharField(max_length=255)
    new_field = models.CharField(max_length=255, default='new_field')
    created_at = models.DateTimeField(auto_now_add=True)


    