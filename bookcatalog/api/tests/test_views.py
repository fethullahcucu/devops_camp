from rest_framework.test import APITestCase
from rest_framework import status
from django.urls import reverse
from ..models import Book


class BookViewTest(APITestCase):
    def test_response_is_correct(self):
        book = Book.objects.create(title="Demo",description="Demo book", author="Demo Author Name")


        url = reverse('api:books')
        response = self.client.get(url, format='json')
        assert response.status_code == status.HTTP_200_OK
        body = response.json()
        assert body[0]['title'] == book.title
        assert body[0]['description'] == book.description
        assert body[0]['author'] == book.author


class HealthViewTest(APITestCase):
    def test_response_is_correct(self):
        url = reverse('api:health')
        response = self.client.get(url, format='json')
        assert response.status_code == status.HTTP_200_OK
        body = response.json()
        assert body['status'] == 'ok' # action test 5


