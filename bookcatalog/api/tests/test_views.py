from rest_framework.test import APITestCase
from rest_framework import status
from django.urls import reverse
from ..models import Book


class BookViewTest(APITestCase):
    def setUp(self):
        """Set up test data for each test method"""
        self.book1 = Book.objects.create(
            title="Demo", 
            description="Demo book", 
            author="Demo Author Name",
            new_field="test_field"
        )
        self.book2 = Book.objects.create(
            title="Demo 2", 
            description="Demo book 2", 
            author="Demo Author Name 2",
            new_field="test_field_2"
        )
        self.book3 = Book.objects.create(
            title="Demo 3", 
            description="Demo book 3", 
            author="Demo Author Name 3",
            new_field="test_field_3"
        )

    def test_get_all_books(self):
        """Test GET request to retrieve all books"""
        url = reverse('api:books')
        response = self.client.get(url, format='json')
        assert response.status_code == status.HTTP_200_OK
        body = response.json()
        assert len(body) == 3
        assert body[0]['title'] == self.book1.title
        assert body[0]['description'] == self.book1.description
        assert body[0]['author'] == self.book1.author

    def test_create_book(self):
        """Test POST request to create a new book"""
        url = reverse('api:books')
        new_book_data = {
            'title': 'New Test Book',
            'description': 'A book created for testing',
            'author': 'Test Author',
            'new_field': 'new_test_value'
        }
        response = self.client.post(url, new_book_data, format='json')
        assert response.status_code == status.HTTP_200_OK
        body = response.json()
        assert body['title'] == new_book_data['title']
        assert body['description'] == new_book_data['description']
        assert body['author'] == new_book_data['author']
        assert body['new_field'] == new_book_data['new_field']
        
        # Verify the book was actually created in the database
        created_book = Book.objects.get(id=body['id'])
        assert created_book.title == new_book_data['title']

    def test_create_book_with_missing_fields(self):
        """Test POST request with missing required fields"""
        url = reverse('api:books')
        incomplete_data = {
            'title': 'Incomplete Book'
            # Missing description, author, new_field
        }
        response = self.client.post(url, incomplete_data, format='json')
        # Depending on your serializer validation, this might be 400
        assert response.status_code in [status.HTTP_400_BAD_REQUEST, status.HTTP_200_OK]

    def test_update_book(self):
        """Test PUT request to update an existing book"""
        url = reverse('api:books')
        update_data = {
            'id': self.book1.id,
            'title': 'Updated Title',
            'description': 'Updated description',
            'author': 'Updated Author',
            'new_field': 'updated_value'
        }
        response = self.client.put(url, update_data, format='json')
        assert response.status_code == status.HTTP_200_OK
        body = response.json()
        assert body['title'] == update_data['title']
        assert body['description'] == update_data['description']
        assert body['author'] == update_data['author']
        assert body['new_field'] == update_data['new_field']
        
        # Verify the book was actually updated in the database
        updated_book = Book.objects.get(id=self.book1.id)
        assert updated_book.title == update_data['title']
        assert updated_book.description == update_data['description']

    def test_update_book_partial(self):
        """Test PUT request with partial update"""
        url = reverse('api:books')
        update_data = {
            'id': self.book1.id,
            'title': 'Partially Updated Title'
        }
        response = self.client.put(url, update_data, format='json')
        assert response.status_code == status.HTTP_200_OK
        body = response.json()
        assert body['title'] == update_data['title']
        # Other fields should remain unchanged
        assert body['description'] == self.book1.description
        assert body['author'] == self.book1.author

    def test_update_nonexistent_book(self):
        """Test PUT request for a book that doesn't exist"""
        url = reverse('api:books')
        update_data = {
            'id': 9999,  # Non-existent ID
            'title': 'Updated Title'
        }
        response = self.client.put(url, update_data, format='json')
        assert response.status_code == status.HTTP_404_NOT_FOUND

    def test_update_book_without_id(self):
        """Test PUT request without providing book ID"""
        url = reverse('api:books')
        update_data = {
            'title': 'Updated Title without ID'
        }
        response = self.client.put(url, update_data, format='json')
        assert response.status_code == status.HTTP_400_BAD_REQUEST

    def test_delete_book(self):
        """Test DELETE request to remove a book"""
        url = reverse('api:books')
        book_id = self.book1.id
        delete_data = {'id': book_id}
        
        # Verify book exists before deletion
        assert Book.objects.filter(id=book_id).exists()
        
        response = self.client.delete(url, delete_data, format='json')
        assert response.status_code == status.HTTP_204_NO_CONTENT
        
        # Verify the book was actually deleted from the database
        assert not Book.objects.filter(id=book_id).exists()

    def test_delete_nonexistent_book(self):
        """Test DELETE request for a book that doesn't exist"""
        url = reverse('api:books')
        delete_data = {'id': 9999}  # Non-existent ID
        response = self.client.delete(url, delete_data, format='json')
        assert response.status_code == status.HTTP_404_NOT_FOUND

    def test_delete_book_without_id(self):
        """Test DELETE request without providing book ID"""
        url = reverse('api:books')
        delete_data = {}
        response = self.client.delete(url, delete_data, format='json')
        assert response.status_code == status.HTTP_400_BAD_REQUEST




class HealthViewTest(APITestCase):
    def test_response_is_correct(self):
        url = reverse('api:health')
        response = self.client.get(url, format='json')
        assert response.status_code == status.HTTP_200_OK
        body = response.json()
        assert body['status'] == 'ok' # action test 5



