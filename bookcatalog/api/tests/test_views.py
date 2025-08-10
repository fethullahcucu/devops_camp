from django.test import TestCase, Client
from django.urls import reverse
from django.contrib.auth.models import User
from ..models import Book
import os
import socket


class BookManagerViewTest(TestCase):
    def setUp(self):
        """Set up test data for each test method"""
        self.client = Client()
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

    def test_book_manager_page_loads(self):
        """Test that the book manager page loads successfully"""
        url = reverse('api:books')  # /api/books/manage/
        response = self.client.get(url)
        
        # Should return HTML page, not JSON
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "Book Manager")
        self.assertContains(response, "Add / Update Book")
        self.assertContains(response, "All Books")

    def test_book_manager_context_data(self):
        """Test that the book manager provides pod information in context"""
        url = reverse('api:books')  # /api/books/manage/
        response = self.client.get(url)
        
        # Check that pod information is in the response
        self.assertContains(response, "Pod Information")
        self.assertContains(response, "Pod Name:")
        self.assertContains(response, "Status:")
        
        # Check context data
        context = response.context
        self.assertIn('pod_name', context)
        self.assertIn('pod_status', context)
        self.assertEqual(context['pod_status'], 'ok')
        
        # Pod name should be either HOSTNAME env var or system hostname
        expected_pod_name = os.environ.get('HOSTNAME') or socket.gethostname()
        self.assertEqual(context['pod_name'], expected_pod_name)

    def test_book_manager_template_used(self):
        """Test that the correct template is used"""
        url = reverse('api:books')  # /api/books/manage/
        response = self.client.get(url)
        
        self.assertTemplateUsed(response, 'api/book_manager.html')

    def test_book_manager_contains_form(self):
        """Test that the book manager page contains the book form"""
        url = reverse('api:books')  # /api/books/manage/
        response = self.client.get(url)
        
        # Check for form elements
        self.assertContains(response, 'id="book-form"')
        self.assertContains(response, 'id="title"')
        self.assertContains(response, 'id="description"')
        self.assertContains(response, 'id="author"')
        self.assertContains(response, 'id="new_field"')
        self.assertContains(response, 'type="submit"')

    def test_book_manager_contains_table(self):
        """Test that the book manager page contains the books table"""
        url = reverse('api:books')  # /api/books/manage/
        response = self.client.get(url)
        
        # Check for table structure
        self.assertContains(response, 'id="books-table"')
        self.assertContains(response, '<th>ID</th>')
        self.assertContains(response, '<th>Title</th>')
        self.assertContains(response, '<th>Description</th>')
        self.assertContains(response, '<th>Author</th>')
        self.assertContains(response, '<th>New Field</th>')
        self.assertContains(response, '<th>Actions</th>')

    def test_book_manager_includes_javascript(self):
        """Test that the book manager includes the JavaScript file"""
        url = reverse('api:books')  # /api/books/manage/
        response = self.client.get(url)
        
        # Check that JavaScript file is included
        self.assertContains(response, 'book_manager.js')

    def test_book_manager_includes_css(self):
        """Test that the book manager includes the CSS file"""
        url = reverse('api:books')  # /api/books/manage/
        response = self.client.get(url)
        
        # Check that CSS file is included
        self.assertContains(response, 'book_manager.css')

    def test_book_manager_responsive_meta_tag(self):
        """Test that the page includes responsive meta tag"""
        url = reverse('api:books')  # /api/books/manage/
        response = self.client.get(url)
        
        self.assertContains(response, 'name="viewport"')
        self.assertContains(response, 'width=device-width, initial-scale=1.0')

    def test_pod_name_environment_variable(self):
        """Test pod name uses HOSTNAME environment variable when available"""
        # Set environment variable
        test_hostname = "test-pod-123"
        os.environ['HOSTNAME'] = test_hostname
        
        url = reverse('api:books')  # /api/books/manage/
        response = self.client.get(url)
        
        # Should use environment variable
        context = response.context
        self.assertEqual(context['pod_name'], test_hostname)
        self.assertContains(response, test_hostname)
        
        # Clean up
        del os.environ['HOSTNAME']

    def test_pod_name_fallback_to_hostname(self):
        """Test pod name falls back to system hostname when HOSTNAME env var not set"""
        # Ensure HOSTNAME env var is not set
        if 'HOSTNAME' in os.environ:
            del os.environ['HOSTNAME']
        
        url = reverse('api:books')  # /api/books/manage/
        response = self.client.get(url)
        
        # Should use system hostname
        expected_hostname = socket.gethostname()
        context = response.context
        self.assertEqual(context['pod_name'], expected_hostname)
        self.assertContains(response, expected_hostname)


