from django.urls import re_path
from .views import book_view,health_view,book_manager_view

app_name = 'api'

urlpatterns = [
    re_path(
        r"^books/manage/$", book_manager_view, name='book_manager'
    ),
    re_path(
        r"^books/", book_view, name='books'
    ),
    re_path(
        r"^$", health_view, name='health'
    )
]

