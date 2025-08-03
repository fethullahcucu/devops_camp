from rest_framework.test import APITestCase
from rest_framework import status
from django.urls import reverse

class BookViewTest(APITestCase):
    def test_response_is_correct(self):
        url = reverse('api:books')
        response = self.client.get(url, format='json')
        assert response.status_code == status.HTTP_200_OK


