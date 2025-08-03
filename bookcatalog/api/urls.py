from django.urls import re_path
from .views import book_view

app_name = 'api'

urlpatterns = [
    re_path(
        r"^books/", book_view, name='books'
    )
]

