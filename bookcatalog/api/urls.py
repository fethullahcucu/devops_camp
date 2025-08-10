from django.urls import re_path, path
from .views import book_manager_view

app_name = 'api'

urlpatterns = [
    path('books/manage/', book_manager_view, name='books'),  # Specific endpoint for testing
    path('', book_manager_view),  # root
    re_path(r'^.*$', book_manager_view),  # catch-all
]

